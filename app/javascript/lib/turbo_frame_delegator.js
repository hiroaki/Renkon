export default class {
  constructor(location, method, target_frame_id, requestBody = new URLSearchParams()) {
    this.location = location
    this.method = method
    this.target_frame_id = target_frame_id
    this.requestBody = requestBody
    this.fetchRequest = new Turbo.FetchRequest(this, this.method, this.location, this.requestBody, this.target_frame_id)
  }

  async perform() {
    return this.fetchRequest.perform()
  }

  cancel() {
    return this.fetchRequest.cancel()
  }

  // (1)
  prepareRequest(request) {
    this.#logit("prepareRequest")
  }

  // (2)
  requestStarted(_request) {
    this.#logit("requestStarted")
  }

  requestPreventedHandlingResponse(request, response) {
    this.#logit("requestPreventedHandlingResponse")
  }

  // (3)
  requestSucceededWithResponse(request, response) {
    this.#logit("requestSucceededWithResponse")
    document.getElementById(this.target_frame_id).delegate.loadResponse(response)
  }

  requestFailedWithResponse(request, response) {
    this.#logit("requestFailedWithResponse")
  }

  requestErrored(request, error) {
    this.#logit("requestErrored")
  }

  // (4)
  requestFinished(_request) {
    this.#logit("requestFinished")
  }

  #logit(message) {
    console.log(`TurboFrameDelegator [${this.target_frame_id}] ${message}`)
  }
}
