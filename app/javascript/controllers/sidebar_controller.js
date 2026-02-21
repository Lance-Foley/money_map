import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "content"]

  connect() {
    const collapsed = localStorage.getItem("sidebar_collapsed") === "true"
    if (collapsed) this.collapse()
  }

  toggle() {
    this.element.classList.toggle("sidebar-collapsed")
    const isCollapsed = this.element.classList.contains("sidebar-collapsed")
    localStorage.setItem("sidebar_collapsed", isCollapsed)
  }

  collapse() {
    this.element.classList.add("sidebar-collapsed")
  }
}
