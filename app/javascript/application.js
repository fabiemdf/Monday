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

document.addEventListener('turbo:load', function() {
  setupResizableColumns();
});

function setupResizableColumns() {
  const tables = document.querySelectorAll('.table-resizable');
  
  tables.forEach(table => {
    const headers = table.querySelectorAll('th');
    
    headers.forEach((header, index) => {
      // Skip the Actions column (last column)
      if (index < headers.length - 1) {
        const resizer = document.createElement('div');
        resizer.classList.add('column-resizer');
        header.appendChild(resizer);
        setupResizer(resizer, header);
      }
    });
  });
}

function setupResizer(resizer, header) {
  let startX, startWidth;
  
  const mouseDownHandler = (e) => {
    startX = e.clientX;
    startWidth = header.offsetWidth;
    
    document.addEventListener('mousemove', mouseMoveHandler);
    document.addEventListener('mouseup', mouseUpHandler);
    
    // Add a class to the body to indicate we're resizing
    document.body.classList.add('resizing-columns');
  };
  
  const mouseMoveHandler = (e) => {
    // Calculate the new width
    const width = startWidth + (e.clientX - startX);
    
    // Set a minimum width of 50px
    if (width >= 50) {
      header.style.width = `${width}px`;
      header.style.minWidth = `${width}px`;
      
      // Save the width to localStorage
      saveColumnWidth(header.textContent.trim(), width);
    }
  };
  
  const mouseUpHandler = () => {
    document.removeEventListener('mousemove', mouseMoveHandler);
    document.removeEventListener('mouseup', mouseUpHandler);
    document.body.classList.remove('resizing-columns');
  };
  
  resizer.addEventListener('mousedown', mouseDownHandler);
  
  // Apply saved width if available
  const savedWidth = getSavedColumnWidth(header.textContent.trim());
  if (savedWidth) {
    header.style.width = `${savedWidth}px`;
    header.style.minWidth = `${savedWidth}px`;
  }
}

function saveColumnWidth(columnName, width) {
  const storageKey = 'claimsTableColumnWidths';
  const savedWidths = JSON.parse(localStorage.getItem(storageKey) || '{}');
  savedWidths[columnName] = width;
  localStorage.setItem(storageKey, JSON.stringify(savedWidths));
}

function getSavedColumnWidth(columnName) {
  const storageKey = 'claimsTableColumnWidths';
  const savedWidths = JSON.parse(localStorage.getItem(storageKey) || '{}');
  return savedWidths[columnName];
}
