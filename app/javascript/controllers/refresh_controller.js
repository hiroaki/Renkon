import { Controller } from "@hotwired/stimulus"
import Queue from "promise-queue"

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
