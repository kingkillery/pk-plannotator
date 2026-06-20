/**
 * Glimpse Native Window Integration
 *
 * Provides a native WebView window using Glimpse (https://github.com/HazAT/glimpse)
 * instead of a browser tab. Adds bidirectional IPC for real-time push/pull
 * of annotations, plan updates, and agent status — making the plan review
 * a persistent, notatable artifact in the agent loop.
 *
 * Environment variables:
 *   PLANNOTATOR_GLIMPSE=1       → force Glimpse
 *   PLANNOTATOR_GLIMPSE=0       → force browser (disable Glimpse)
 *   unset                       → auto-detect (try Glimpse, fall back to browser)
 *
 * Glimpse is always disabled for remote/devcontainer sessions.
 * Glimpse windows are intentionally always-on-top while open. Users should
 * close them, use them later, or minimize them rather than letting them hide
 * behind editor/browser windows.
 */

import { isRemoteSession } from "./remote";

// --- Types ---

export interface GlimpseWindowOptions {
  /** Server URL to load in the iframe */
  serverUrl: string;
  /** Window title */
  title?: string;
  /** Window width (default: 960) */
  width?: number;
  /** Window height (default: 740) */
  height?: number;
  /** Called when window sends a message via glimpse.send() */
  onMessage?: (data: GlimpseMessage) => void;
  /** Called when window is closed */
  onClosed?: () => void;
}

export interface GlimpseMessage {
  /** Message type: 'approve', 'deny', 'annotation', 'feedback', 'status', etc. */
  type: string;
  /** Arbitrary payload data */
  [key: string]: unknown;
}

export interface GlimpseHandle {
  /** Push data into the window (agent → UI). Evaluates JS in the Glimpse shell. */
  push: (data: GlimpseMessage) => void;
  /** Close the window */
  close: () => void;
  /** Promise that resolves when window is closed */
  readonly closed: Promise<void>;
  /** Whether the window is still open */
  readonly isOpen: boolean;
  /** Register an additional message handler */
  onMessage: (handler: (data: GlimpseMessage) => void) => void;
}

// --- Module state ---

type GlimpseModule = {
  open: (html: string, options?: Record<string, unknown>) => GlimpseWindowInstance;
  getNativeHostInfo: () => { path: string; platform: string; buildHint: string };
};

type GlimpseWindowInstance = {
  on: (event: string, handler: (...args: unknown[]) => void) => void;
  send: (js: string) => void;
  close: () => void;
};

let _glimpse: GlimpseModule | null = null;
let _checked = false;

// --- Availability check ---

/**
 * Check if Glimpse is available and should be used.
 */
export function isGlimpseAvailable(): boolean {
  if (isRemoteSession()) return false;

  const env = process.env.PLANNOTATOR_GLIMPSE;
  if (env === "0" || env === "false" || env === "disabled") return false;

  if (!_checked) {
    _checked = true;
    try {
      _glimpse = require("glimpseui") as GlimpseModule;
      // Verify native binary is compiled
      const info = _glimpse.getNativeHostInfo();
      if (!info?.path) _glimpse = null;
    } catch {
      _glimpse = null;
    }
  }

  return _glimpse !== null;
}

// --- Shell HTML ---

/**
 * Generate the shell HTML that wraps an iframe to the server URL
 * with a bidirectional message bridge between Glimpse IPC and the iframe.
 */
export function createGlimpseShellHtml(serverUrl: string): string {
  return `<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
*{margin:0;padding:0}
html,body{width:100%;height:100%;overflow:hidden;background:#0f0f23}
iframe{width:100%;height:100%;border:none}
</style>
</head>
<body>
<iframe id="app" src="${serverUrl}"></iframe>
<script>
(function() {
  var CH = 'plannotator-ipc';
  var iframe = document.getElementById('app');

  // iframe -> Glimpse native (postMessage -> glimpse.send)
  window.addEventListener('message', function(e) {
    if (e.data && e.data.__ch === CH && e.data.payload) {
      if (window.glimpse) {
        window.glimpse.send(e.data.payload);
      }
    }
  });

  // Glimpse native (win.send) -> iframe (postMessage)
  // Server calls: win.send('window.__glimpseIn({...})')
  window.__glimpseIn = function(data) {
    if (iframe.contentWindow) {
      iframe.contentWindow.postMessage({
        __ch: CH, __fromG: true, d: data
      }, '*');
    }
  };

  // Signal to iframe that Glimpse bridge shell is ready
  iframe.addEventListener('load', function() {
    if (iframe.contentWindow) {
      iframe.contentWindow.postMessage({
        __ch: CH, __ready: true
      }, '*');
    }
  });
})();
</script>
</body>
</html>`;
}

/**
 * Script tag to inject into the React app HTML when running inside Glimpse.
 * Sets up the iframe-side bridge: React app <-> parent shell <-> Glimpse native.
 */
export const GLIMPSE_BRIDGE_SCRIPT = `<script id="plannotator-glimpse-bridge">
(function() {
  var CH = 'plannotator-ipc';
  var isIframe = (window.parent !== window);
  var glimpseReady = false;
  var pendingSends = [];

  // Listen for messages from Glimpse shell (parent)
  window.addEventListener('message', function(e) {
    if (!e.data || e.data.__ch !== CH) return;

    if (e.data.__ready) {
      glimpseReady = true;
      window.__PLANNOTATOR_GLIMPSE__ = true;
      window.dispatchEvent(new CustomEvent('plannotator:glimpse-ready'));
      // Flush pending sends
      for (var i = 0; i < pendingSends.length; i++) {
        window.parent.postMessage({ __ch: CH, payload: pendingSends[i] }, '*');
      }
      pendingSends = [];
      return;
    }

    if (e.data.__fromG) {
      // Push from agent/server -> dispatch as custom event for React app
      window.dispatchEvent(new CustomEvent('plannotator:glimpse-push', {
        detail: e.data.d
      }));
    }
  });

  // Send message to Glimpse shell (parent) -> native IPC
  window.__glimpseSend = function(data) {
    if (!isIframe) return;
    if (glimpseReady) {
      window.parent.postMessage({ __ch: CH, payload: data }, '*');
    } else {
      pendingSends.push(data);
    }
  };

  // Convenience: check if running in Glimpse
  window.__isGlimpse = function() {
    return glimpseReady || isIframe;
  };
})();
</script>`;

// --- Window management ---

/**
 * Open a Glimpse native window pointing at the Plannotator server.
 * Returns null if Glimpse is not available.
 */
export async function openGlimpseWindow(
  options: GlimpseWindowOptions
): Promise<GlimpseHandle | null> {
  if (!isGlimpseAvailable() || !_glimpse) return null;

  try {
    const shellHtml = createGlimpseShellHtml(options.serverUrl);
    const handlers: ((data: GlimpseMessage) => void)[] = [];
    let resolveClosed: () => void;
    const closedPromise = new Promise<void>((resolve) => {
      resolveClosed = resolve;
    });
    let isOpen = true;

    if (options.onMessage) handlers.push(options.onMessage);

    const win = _glimpse.open(shellHtml, {
      width: options.width ?? 960,
      height: options.height ?? 740,
      title: options.title ?? "Plannotator",
      floating: true,
    });

    win.on("message", (data: unknown) => {
      const msg = data as GlimpseMessage;
      for (const handler of handlers) {
        try {
          handler(msg);
        } catch {
          // Don't let handler errors crash the bridge
        }
      }
    });

    win.on("closed", () => {
      isOpen = false;
      resolveClosed();
      options.onClosed?.();
    });

    const handle: GlimpseHandle = {
      push(data: GlimpseMessage) {
        if (!isOpen) return;
        const js = `window.__glimpseIn(${JSON.stringify(data)})`;
        win.send(js);
      },
      close() {
        if (isOpen) win.close();
      },
      get closed() {
        return closedPromise;
      },
      get isOpen() {
        return isOpen;
      },
      onMessage(handler: (data: GlimpseMessage) => void) {
        handlers.push(handler);
      },
    };

    return handle;
  } catch (err) {
    console.error("[Glimpse] Failed to open window:", err);
    return null;
  }
}

/**
 * Inject the Glimpse bridge script into HTML content.
 * Adds the script before </body> so the React app can use
 * window.__glimpseSend() and listen for 'plannotator:glimpse-push' events.
 */
export function injectGlimpseBridge(html: string): string {
  const closeTag = "</body>";
  const idx = html.toLowerCase().indexOf(closeTag);
  if (idx !== -1) {
    return html.slice(0, idx) + GLIMPSE_BRIDGE_SCRIPT + html.slice(idx);
  }
  // Fallback: append to end
  return html + GLIMPSE_BRIDGE_SCRIPT;
}
