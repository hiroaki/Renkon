import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.info('refresh_controller');
  }

  // refresh all channels
  all() {
    const channel_frames = document.getElementById('channels').querySelectorAll('turbo-frame');

    channel_frames.forEach(channel_frame => {
      Turbo.fetch(channel_frame.dataset['urlForRefresh'], {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
          'Turbo-Frame': channel_frame.id,
          'Accept': 'text/vnd.turbo-stream.html, text/html, application/xhtml+xml'
        }
      })
      .then((response) => {
        document.getElementById(channel_frame.id).delegate.loadResponse(new Turbo.FetchResponse(response))
      });
    });
  }
}
