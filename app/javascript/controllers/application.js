// import { Application } from "@hotwired/stimulus"
//
// const application = Application.start()
//
// --> https://stimulus.hotwired.dev/reference/actions#keyboardevent-filter
import { Application, defaultSchema } from "@hotwired/stimulus"
const customSchema = {
  ...defaultSchema,
  keyMappings: { ...defaultSchema.keyMappings, backspace: 'Backspace' },
}
console.log(customSchema);
const application = Application.start(document.documentElement, customSchema)

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
