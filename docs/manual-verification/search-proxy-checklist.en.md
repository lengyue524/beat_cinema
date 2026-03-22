# Search Proxy Manual Verification Checklist

Goal: Verify song search uses proxy settings correctly for YouTube / Bilibili and ensure no regressions.

## Preconditions

- BeatSaber path is configured and valid.
- Search panel is available and platform switch works (YouTube / Bilibili).
- Prepare a stable keyword (an English song name is recommended).
- Prepare a valid custom proxy (for example: `127.0.0.1:7890`).

## Case 1: Proxy Mode = None

Steps:
- Set proxy mode to `None` in settings.
- Search the keyword on YouTube.
- Search the same keyword on Bilibili.

Expected:
- Search requests are sent and return results (or a user-friendly error).
- Logs contain `proxyMode=none` and `proxyApplied=false`.

## Case 2: Proxy Mode = Custom (valid address)

Steps:
- Set proxy mode to `Custom`, enter a valid proxy address, and save.
- Search on YouTube.
- Search on Bilibili.

Expected:
- Search works normally.
- Logs contain `proxyMode=custom` and `proxyApplied=true`.

## Case 3: Proxy Mode = Custom (invalid address)

Steps:
- Keep `Custom` mode, enter an invalid proxy address, and save.
- Run search on YouTube / Bilibili.

Expected:
- Search failure shows understandable feedback and does not freeze the page.
- User can update settings and search again immediately.

## Case 4: Proxy Mode = System

Steps:
- Switch mode to `System`.
- Run search on YouTube / Bilibili.

Expected:
- Logs contain `proxyMode=system`.
- If system proxy can be resolved, `proxyApplied=true`; otherwise `proxyApplied=false`.

## Case 5: Hot Switch Takes Effect Immediately

Steps:
- In one app session, switch modes in order: `none -> custom -> system`.
- Trigger one search right after each switch (at least once on both platforms).

Expected:
- No app restart required.
- New requests immediately follow the latest mode (verify through logs).

## Regression Checks

- Trigger `Play in app` from search results and verify it still works.
- Trigger video download from search results and verify download flow still works.
- Failure messages for playback/download remain understandable and non-blocking.

## Verification Record Template (recommended)

- Verification date:
- Verified by:
- Proxy environment notes:
- Result: Pass / Fail
- Notes (failure symptoms and log snippets):
