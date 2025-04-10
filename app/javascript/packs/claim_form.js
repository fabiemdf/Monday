// app/javascript/packs/claim_form.js

document.addEventListener('turbolinks:load', function() {
    // Only run on edit/new claim pages
    if (!document.querySelector('.claim-form')) return;
  
    // Get form elements
    const form = document.querySelector('.claim-form');
    const saveButton = document.getElementById('save-button');
    const saveStatus = document.getElementById('save-status');
    const resetButton = document.getElementById('confirm-reset');
    const inputs = form.querySelectorAll('input, select, textarea');
    const fieldIndicators = document.querySelectorAll('.field-indicator');
    
    // Track changed fields
    let changedFields = new Set();
    let formChanged = false;
    
    // Format currency inputs
    const amountField = document.getElementById('claim_amount');
    if (amountField) {
      amountField.addEventListener('blur', function() {
        if (this.value) {
          // Ensure value is properly formatted as a number
          const value = parseFloat(this.value.replace(/[^0-9.-]+/g, ''));
          if (!isNaN(value)) {
            this.value = value.toFixed(2);
          }
        }
      });
    }
  
    // Function to check if a field has changed from its original value
    function checkFieldChanged(input) {
      const originalValue = input.dataset.original || '';
      const currentValue = input.value || '';
      
      // Find the field indicator for this input
      const fieldGroup = input.closest('.input-group');
      if (!fieldGroup) return;
      
      const indicator = fieldGroup.querySelector('.field-indicator i');
      if (!indicator) return;
      
      if (currentValue !== originalValue) {
        // Field has changed
        changedFields.add(input.id);
        indicator.className = 'bi bi-pencil-fill text-warning';
      } else {
        // Field is unchanged
        changedFields.delete(input.id);
        indicator.className = 'bi bi-circle-fill text-muted';
      }
      
      // Update overall form status
      updateFormStatus();
    }
    
    // Update form status based on changed fields
    function updateFormStatus() {
      formChanged = changedFields.size > 0;
      
      if (saveButton) {
        saveButton.disabled = !formChanged;
      }
      
      if (saveStatus) {
        if (formChanged) {
          saveStatus.textContent = `${changedFields.size} field(s) changed`;
          saveStatus.className = 'me-3 text-primary';
        } else {
          saveStatus.textContent = 'No changes';
          saveStatus.className = 'me-3 text-muted';
        }
      }
    }
    
    // Add change listeners to all inputs
    inputs.forEach(input => {
      input.addEventListener('input', () => {
        checkFieldChanged(input);
      });
      
      input.addEventListener('change', () => {
        checkFieldChanged(input);
      });
    });
  
    // Confirmation before leaving page with unsaved changes
    window.addEventListener('beforeunload', (e) => {
      if (formChanged) {
        e.preventDefault();
        e.returnValue = 'You have unsaved changes. Are you sure you want to leave?';
        return e.returnValue;
      }
    });
  
    // Reset the change tracker when form is submitted
    form.addEventListener('submit', () => {
      formChanged = false;
    });
    
    // Handle form reset
    if (resetButton) {
      resetButton.addEventListener('click', () => {
        inputs.forEach(input => {
          if (input.dataset.original !== undefined) {
            input.value = input.dataset.original || '';
            checkFieldChanged(input);
          }
        });
        
        // Also update status preview if it exists
        if (statusSelect && statusPreview) {
          updateStatusPreview();
        }
        
        // Close the modal
        const modal = document.getElementById('resetFormModal');
        const bsModal = bootstrap.Modal.getInstance(modal);
        if (bsModal) {
          bsModal.hide();
        }
      });
    }
  
    // Status color preview
    const statusSelect = document.getElementById('claim_status');
    const statusPreview = document.getElementById('status_preview');
    
    if (statusSelect && statusPreview) {
      function updateStatusPreview() {
        const status = statusSelect.value;
        let badgeClass = 'badge ';
        
        switch(status) {
          case 'pending':
            badgeClass += 'bg-warning';
            break;
          case 'approved':
            badgeClass += 'bg-success';
            break;
          case 'rejected':
            badgeClass += 'bg-danger';
            break;
          case 'in_progress':
            badgeClass += 'bg-info';
            break;
          default:
            badgeClass += 'bg-secondary';
            break;
        }
        
        // Remove old classes and add new ones
        statusPreview.className = badgeClass;
        statusPreview.textContent = status.replace('_', ' ').replace(/\b\w/g, l => l.toUpperCase());
      }
      
      // Initialize and add change listener
      updateStatusPreview();
      statusSelect.addEventListener('change', updateStatusPreview);
    }
    
    // Add save in progress indicator
    form.addEventListener('submit', function() {
      if (saveButton) {
        saveButton.disabled = true;
        saveButton.innerHTML = '<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span> Updating...';
      }
      
      if (saveStatus) {
        saveStatus.textContent = 'Saving changes...';
        saveStatus.className = 'me-3 text-info';
      }
    });
  });