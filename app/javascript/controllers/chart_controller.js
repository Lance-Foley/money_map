import { Controller } from "@hotwired/stimulus"
import Chart from "chart.js"

export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: { type: Object, default: {} }
  }

  connect() {
    this.chart = new Chart(this.element, {
      type: this.typeValue,
      data: this.dataValue,
      options: {
        ...this.optionsValue,
        responsive: true,
        maintainAspectRatio: false
      }
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
}
