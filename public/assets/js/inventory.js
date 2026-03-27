document.addEventListener('DOMContentLoaded', async () => {
  try {
    const response = await fetch('http://localhost:3000/api/inventory');
    const inventory = await response.json();
    
    const container = document.getElementById('inventoryContainer');
    container.innerHTML = inventory.map(item => `
      <div class="col-md-3 mb-4">
        <div class="card blood-card text-center">
          <div class="card-body">
            <h3 class="card-title">${item.BloodType}</h3>
            <p class="card-text display-4">${item.Quantity}</p>
            <small class="text-muted">units available</small>
          </div>
        </div>
      </div>
    `).join('');
  } catch (err) {
    document.getElementById('inventoryContainer').innerHTML = `
      <div class="col-12 alert alert-danger">Failed to load inventory: ${err.message}</div>
    `;
  }
});