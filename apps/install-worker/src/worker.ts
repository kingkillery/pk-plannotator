import installScript from "./install.sh";

const INSTALL_PATH = "/install.sh";
const SCRIPT_VERSION = "0.19.22-pk.2";

export default {
  fetch(request: Request): Response {
    const url = new URL(request.url);

    if (url.pathname !== INSTALL_PATH) {
      return new Response("Not found", { status: 404 });
    }

    if (request.method !== "GET" && request.method !== "HEAD") {
      return new Response("Method not allowed", {
        status: 405,
        headers: { Allow: "GET, HEAD" },
      });
    }

    const headers = new Headers({
      "Content-Type": "text/x-shellscript; charset=utf-8",
      "Cache-Control": "no-cache",
      "ETag": `"${SCRIPT_VERSION}"`,
      "X-Content-Type-Options": "nosniff",
      "X-Script-Version": SCRIPT_VERSION,
    });

    return new Response(request.method === "HEAD" ? null : installScript, { headers });
  },
};
