// skyyytmusic bridge: lets skyyytlike read and press the YouTube Music like
// button in this window, so liking from the bar updates the page at once.
// Requests come from the native host "skyyytmusic" (../host), which skyyytlike
// reaches over a Unix socket. No WebDriver/Marionette: with those the page sees
// navigator.webdriver = true and YouTube stops streaming after one minute.

// Runs in the page: returns the like status, after a click if asked.
function likeButton(click) {
  const r = document.querySelector("ytmusic-player-bar ytmusic-like-button-renderer");
  if (r) {
    if (click) (r.querySelector("#button-shape-like button") || r.querySelector("#like")).click();
    return r.getAttribute("like-status") || "INDIFFERENT";
  }
  const v = document.querySelector("segmented-like-dislike-button-view-model like-button-view-model button");
  if (!v) return null;
  if (click) v.click();
  return v.getAttribute("aria-pressed") === "true" ? "LIKE" : "INDIFFERENT";
}

async function handle(msg) {
  const tabs = await browser.tabs.query({ url: "https://music.youtube.com/*" });
  const tab = tabs.find((t) => t.audible) || tabs.find((t) => t.active) || tabs[0];
  if (!tab) return null;
  const [value] = await browser.tabs.executeScript(tab.id, {
    code: `(${likeButton})(${msg.click === true})`,
  });
  return value ?? null;
}

function connect() {
  const port = browser.runtime.connectNative("skyyytmusic");
  port.onMessage.addListener(async (msg) => {
    try {
      port.postMessage({ id: msg.id, value: await handle(msg) });
    } catch (e) {
      port.postMessage({ id: msg.id, error: String(e) });
    }
  });
  // The host only goes away if it crashed or could not start: retry later.
  port.onDisconnect.addListener(() => setTimeout(connect, 10000));
}

connect();
