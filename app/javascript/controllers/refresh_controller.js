import { Controller } from "@hotwired/stimulus"
import Queue from "promise-queue"
import TurboFrameDelegator from "lib/turbo_frame_delegator"
import { getCsrfToken } from 'lib/schema'

class RefreshChanelsDelegator extends TurboFrameDelegator {
  // override
  prepareRequest(request) {
    super.prepareRequest(request)
    console.log("request", request)

    if (!request.isSafe) {
      const token = getCsrfToken()
      if (token) {
        request.headers["X-CSRF-Token"] = token
      }
    }
  }
}

export default class extends Controller {
  static values = { concurrency: Number }

  initialize() {
    this.concurrencyValue ||= 4;
    console.info(`refresh_controller#new: this.concurrencyValue=[${this.concurrencyValue}]`);
  }

  // refresh all subscriptions
  all() {
    const generateFetchFunction = (urlRefresh, method, frame_id) => {
      return async () => new RefreshChanelsDelegator(urlRefresh, method, frame_id).perform();
    }

    const que = new Queue(this.concurrencyValue);

    document.getElementById('subscriptions').querySelectorAll('li').forEach(li => {
      const turboFrame = li.querySelector('turbo-frame');
      if (turboFrame) { // "trash" has no turbo-frame
        que.add(
          generateFetchFunction(li.dataset['urlRefresh'], 'PATCH', turboFrame.id)
        )
      }
    });
  }

  // 試作：低レベル関数 Turbo.fetch を利用したもの
  _all() {
    const generateFetchFunction = (urlRefresh, method, frame_id) => {
      return async () => {
        return await Turbo.fetch(urlRefresh, {
          method: method,
          headers: {
            'X-CSRF-Token': getCsrfToken(),
            'Turbo-Frame': frame_id,
            'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
          }
        });
      }
    };

    const que = new Queue(this.concurrencyValue);

    document.getElementById('subscriptions').querySelectorAll('li').forEach(li => {
      const turboFrame = li.querySelector('turbo-frame');
      if (turboFrame) { // "trash" has no turbo-frame
        que.add(
          generateFetchFunction(li.dataset['urlRefresh'], 'PATCH', turboFrame.id)
        )
        .then((response) => {
          document.getElementById(channel_frame.id).delegate.loadResponse(new Turbo.FetchResponse(response));
        });
      }
    });
  }
}
