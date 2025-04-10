// app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"
import { Dropdown } from "bootstrap"

// Connects to data-controller="dropdown"
export default class extends Controller {
  connect() {
    this.dropdown = new Dropdown(this.element)
  }

  disconnect() {
    if (this.dropdown) {
      this.dropdown.dispose()
    }
  }
}