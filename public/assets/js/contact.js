document.getElementById('contactForm').addEventListener('submit', async (e) => {
  e.preventDefault();
  
  const formData = {
    name: e.target[0].value,
    email: e.target[1].value,
    phone: e.target[2].value,
    message: e.target[3].value
  };

  try {
    const response = await fetch('http://localhost:3000/api/contact', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(formData)
    });
    
    if (response.ok) {
      alert('Message sent successfully!');
      e.target.reset();
    } else {
      throw new Error('Failed to send message');
    }
  } catch (err) {
    alert('Error: ' + err.message);
  }
});