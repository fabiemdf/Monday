// app/javascript/application.js
// Configure your import map in config/importmap.rb

import "@hotwired/turbo-rails"
import "controllers"
import * as bootstrap from "bootstrap"

// Make bootstrap globally available
window.bootstrap = bootstrap

// Handle Bootstrap components with Turbo
document.addEventListener("turbo:load", () => {
  // Initialize tooltips
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl)
  })

  // Initialize popovers
  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  var popoverList = popoverTriggerList.map(function (popoverTriggerEl) {
    return new bootstrap.Popover(popoverTriggerEl)
  })

  // Initialize dropdowns
  var dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'))
  var dropdownList = dropdownElementList.map(function (dropdownToggleEl) {
    return new bootstrap.Dropdown(dropdownToggleEl)
  })
})

// Clean up Bootstrap components before Turbo replaces the body
document.addEventListener("turbo:before-render", () => {
  // Clean up tooltips
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'))
  tooltipTriggerList.forEach(function (tooltipTriggerEl) {
    var tooltip = bootstrap.Tooltip.getInstance(tooltipTriggerEl)
    if (tooltip) {
      tooltip.dispose()
    }
  })

  // Clean up popovers
  var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'))
  popoverTriggerList.forEach(function (popoverTriggerEl) {
    var popover = bootstrap.Popover.getInstance(popoverTriggerEl)
    if (popover) {
      popover.dispose()
    }
  })

  // Clean up dropdowns
  var dropdownElementList = [].slice.call(document.querySelectorAll('.dropdown-toggle'))
  dropdownElementList.forEach(function (dropdownToggleEl) {
    var dropdown = bootstrap.Dropdown.getInstance(dropdownToggleEl)
    if (dropdown) {
      dropdown.dispose()
    }
  })
})



const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
