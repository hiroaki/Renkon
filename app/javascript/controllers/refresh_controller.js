import { Controller } from "@hotwired/stimulus"
import Queue from "promise-queue"

function _getMetaElement(name) {
    return document.querySelector(`meta[name="${name}"]`);
  }

function _getMetaContent(name) {
    const element = _getMetaElement(name);
    return element && element.content;
  }

function _getCookieValue(cookieName) {
    if (cookieName != null) {
      const cookies = document.cookie ? document.cookie.split("; ") : []
      const cookie = cookies.find((cookie) => cookie.startsWith(cookieName))
      if (cookie) {
        const value = cookie.split("=").slice(1).join("=")
        return value ? decodeURIComponent(value) : undefined
      }
    }
  }

export default class extends Controller {
  static values = { concurrency: Number }

  connect() {
    console.info('refresh_controller#connect');
  }

  initialize() {
    console.info('refresh_controller#new');
    this.concurrencyValue ||= 4;
    console.log(`this.concurrencyValue=[${this.concurrencyValue}]`)
  }

  // refresh all channels
  all() {

    class RefreshDelegator {
      constructor(location, method, target_frame_id) {
        this.location = location
        this.method = method
        this.target_frame_id = target_frame_id;
        this.fetchRequest = new Turbo.FetchRequest(this, this.method, this.location, new URLSearchParams(), this.target_frame_id)
      }

      perform() {
        this.fetchRequest.perform()
      }

      // (1)
      prepareRequest(request) {
        console.log("prepareRequest")
        if (!request.isSafe) {
          const token = _getCookieValue(_getMetaContent("csrf-param")) || _getMetaContent("csrf-token")
          if (token) {
            request.headers["X-CSRF-Token"] = token
          }
        }
      }

      // (2)
      requestStarted(_request) {
        console.log("requestStarted")
      }

      requestPreventedHandlingResponse(request, response) {
        console.log("requestPreventedHandlingResponse")
      }

      // (3)
      requestSucceededWithResponse(request, response) {
        console.log("requestSucceededWithResponse")
        document.getElementById(this.target_frame_id).delegate.loadResponse(response)
      }

      requestFailedWithResponse(request, response) {
        console.log("requestFailedWithResponse")
      }

      requestErrored(request, error) {
        console.log("requestErrored")
      }

      // (4)
      requestFinished(_request) {
        console.log("requestFinished")
      }

    }

    (new RefreshDelegator("/channels/3/fetch", "PATCH", "channel_3")).perform()
  }

  _all() {
    const generate_fetch_function = (url_for_refresh, frame_id) => {
      return async () => {
        console.log(`[${frame_id}] start ${url_for_refresh}`);

        const response = await Turbo.fetch(url_for_refresh, {
          method: 'PATCH',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
            'Turbo-Frame': frame_id,
            'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
          }
        });

        console.log(`[${frame_id}] end`);
        return response;
      }
    };

    const que = new Queue(this.concurrencyValue);

    document.getElementById('channels').querySelectorAll('turbo-frame').forEach(channel_frame => {
      que.add(
        generate_fetch_function(channel_frame.dataset['urlForRefresh'], channel_frame.id)
      )
      .then((response) => {
        document.getElementById(channel_frame.id).delegate.loadResponse(new Turbo.FetchResponse(response));
      });
    });
  }

}
