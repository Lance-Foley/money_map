import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="frequency-toggle"
// Shows/hides the custom interval fields based on the frequency select value.
export default class extends Controller {
  static targets = ["customFields"]

  connect() {
    this.toggle()
  }

  toggle() {
    const select = this.element.querySelector("[data-frequency-select]")
    if (!select) return

    const isCustom = select.value === "custom"
    this.customFieldsTargets.forEach((el) => {
      el.classList.toggle("hidden", !isCustom)
    })
  }
}
