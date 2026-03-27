document.addEventListener('DOMContentLoaded', () => {
  // Load donors on page load
  loadDonors();

  // Handle donor form submission
  document.getElementById('donorForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const donor = {
      DonorName: document.getElementById('donorName').value,
      Age: parseInt(document.getElementById('age').value),
      BloodType: document.getElementById('bloodType').value,
      ContactNumber: document.getElementById('contact').value,
      InitialDonation: parseFloat(document.getElementById('initialDonation')?.value || 0)
    };


    try {
      const response = await fetch('http://localhost:3000/api/donors', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(donor)
      });
      
      if (response.ok) {
        alert('Donor registered successfully!');
        document.getElementById('donorForm').reset();
        loadDonors();
      } else {
        alert('Error: ' + await response.text());
      }
    } catch (err) {
      alert('Network error: ' + err.message);
    }
  });
});

async function loadDonors() {
  try {
    const response = await fetch('http://localhost:3000/api/donors');
    const donors = await response.json();
    
    const tbody = document.querySelector('#donorsTable tbody');
    tbody.innerHTML = donors.map(donor => `
      <tr>
        <td>${donor.DonorName}</td>
        <td>${donor.BloodType}</td>
        <td>${donor.Age}</td>
      </tr>
    `).join('');
  } catch (err) {
    console.error('Failed to load donors:', err);
  }
}