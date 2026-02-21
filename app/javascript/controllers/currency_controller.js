import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  format(event) {
    const value = event.target.value.replace(/[^0-9.]/g, "")
    const parts = value.split(".")
    if (parts.length > 2) {
      event.target.value = parts[0] + "." + parts.slice(1).join("")
    }
    if (parts[1] && parts[1].length > 2) {
      event.target.value = parts[0] + "." + parts[1].substring(0, 2)
    }
  }
}
