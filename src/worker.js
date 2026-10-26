// Redirect www to the apex domain; everything else is served from static assets.
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.hostname === "www.ebardelli.com") {
      url.hostname = "ebardelli.com";
      return Response.redirect(url.toString(), 301);
    }
    return env.ASSETS.fetch(request);
  },
};
