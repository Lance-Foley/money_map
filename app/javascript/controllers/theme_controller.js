import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["icon"]

  connect() {
    this.applyTheme()
  }

  toggle() {
    const current = localStorage.getItem("theme") || "system"
    const next = current === "light" ? "dark" : current === "dark" ? "system" : "light"
    localStorage.setItem("theme", next)
    this.applyTheme()
  }

  applyTheme() {
    const theme = localStorage.getItem("theme") || "system"
    const isDark = theme === "dark" || (theme === "system" && window.matchMedia("(prefers-color-scheme: dark)").matches)
    document.documentElement.classList.toggle("dark", isDark)
  }
}
