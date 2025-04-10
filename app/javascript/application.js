// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "./controllers"

import React from "react"
import { createRoot } from "react-dom/client"
import App from "./components/App"

document.addEventListener("turbo:load", () => {
  const container = document.getElementById("root")
  if (container) {
    const root = createRoot(container)
    root.render(<App />)
  }
})
import "controllers"
