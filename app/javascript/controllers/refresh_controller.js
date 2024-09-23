import { Controller } from "@hotwired/stimulus"
import Queue from "promise-queue"

export default class extends Controller {
  connect() {
    console.info('refresh_controller');
  }

  // refresh all channels
  all() {
    const channel_frames = document.getElementById('channels').querySelectorAll('turbo-frame');

    const generate_promise = function(channel_frame) {
      return function() {
        return new Promise(async function(resolve, reject) {
          console.log("["+ channel_frame.id +"] start");

          const response = await Turbo.fetch(channel_frame.dataset['urlForRefresh'], {
            method: 'PATCH',
            headers: {
              'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
              'Turbo-Frame': channel_frame.id,
              'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
            }
          })

          document.getElementById(channel_frame.id).delegate.loadResponse(new Turbo.FetchResponse(response));

          console.log("["+ channel_frame.id +"] end");
          resolve(response);
        });
      }
    }

    const que = new Queue(2);

    channel_frames.forEach(channel_frame => {
      que.add(generate_promise(channel_frame));
    });
  }
}
