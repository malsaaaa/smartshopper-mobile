// ── Firebase Initialization ───────────────────────────────────────────────────

// Initialize Firebase
firebase.initializeApp(window.firebaseConfig);
const auth = firebase.auth();
const db   = firebase.firestore();

// ── State Management ──────────────────────────────────────────────────────────

let products = [];
let retailers = [];
let prices = [];
let users = [];
let notificationHistory = [];

function normalizeRetailerRecord(retailer) {
  const name = (retailer?.name || '').trim();
  const normalizedName = name.toLowerCase();

  if (normalizedName === 'giant') {
    return {
      ...retailer,
      name: 'myAEON2go',
      website: 'https://www.lotuss.com.my/en',
      icon: 'https://thumbor.asia-southeast1.aeon-my-prod.e.spresso.com/unsafe/web2-assets.myboxed.com.my/public/images/32x25_optimized.png',
      logoUrl: 'https://thumbor.asia-southeast1.aeon-my-prod.e.spresso.com/unsafe/web2-assets.myboxed.com.my/public/images/32x25_optimized.png',
    };
  }

  return retailer;
}

const NOTIFICATION_HISTORY_KEY = 'smartshopper_notification_history';

function loadNotificationHistory() {
  try {
    const saved = localStorage.getItem(NOTIFICATION_HISTORY_KEY);
    if (saved) {
      notificationHistory = JSON.parse(saved);
    }
  } catch (error) {
    console.warn('Unable to load notification history:', error);
  }
  return notificationHistory;
}

function saveNotificationHistory() {
  localStorage.setItem(NOTIFICATION_HISTORY_KEY, JSON.stringify(notificationHistory.slice(0, 20)));
}

function pushNotificationHistory(entry) {
  notificationHistory = [entry, ...notificationHistory].slice(0, 20);
  saveNotificationHistory();
  renderNotifications();
}

function renderNotificationHistory() {
  const tbody = document.getElementById('notification-history-body');
  if (!tbody) return;

  if (!notificationHistory.length) {
    tbody.innerHTML = `
      <tr>
        <td colspan="5" style="text-align:center;color:var(--text-3);padding:24px">No notification runs yet.</td>
      </tr>`;
    return;
  }

  tbody.innerHTML = notificationHistory.map(entry => `
    <tr>
      <td style="color:var(--text-2);font-size:.82rem">${new Date(entry.at).toLocaleString()}</td>
      <td><strong>${entry.type}</strong></td>
      <td>${entry.title}</td>
      <td><span class="notif-history ${entry.status}">${entry.status}</span></td>
      <td style="font-size:.78rem;color:var(--text-2)">${entry.channel}</td>
    </tr>
  `).join('');
}

function renderNotifications() {
  renderNotificationHistory();
}

// ── Authentication ────────────────────────────────────────────────────────────

// Check auth state
auth.onAuthStateChanged(async user => {
  const loadingScreen = document.getElementById('loading-screen');
  const loginScreen   = document.getElementById('login-screen');
  const appContainer  = document.getElementById('app');

  if (user) {
    try {
      // Fetch user profile to check for admin privileges
      const userDoc = await db.collection('users').doc(user.uid).get();
      const userData = userDoc.data();

      if (userData && userData.isAdmin === true) {
        // Logged in as Admin
        loadingScreen.style.display = 'none';
        loginScreen.style.display = 'none';
        appContainer.style.display = 'flex';
        document.querySelector('.admin-name').textContent = userData.name || user.email.split('@')[0];
        
        // Update Admin Role in sidebar footer dynamically
        const roleEl = document.querySelector('.admin-role');
        if (roleEl) {
          roleEl.textContent = userData.isSuperAdmin ? 'Super Admin' : 'Admin';
        }

        // Auto-promote Syed Danish to Super Admin if not already
        if (user.email === 'sydnish03@gmail.com' && !userData.isSuperAdmin) {
          db.collection('users').doc(user.uid).update({
            isSuperAdmin: true,
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
          }).then(() => {
            showToast('🌟 Account upgraded to Super Admin!');
            if (roleEl) roleEl.textContent = 'Super Admin';
          }).catch(err => console.error('Failed to auto-promote:', err));
        }

        initDashboard();
      } else {
        // Not an admin - sign out and show error
        await auth.signOut();
        loadingScreen.style.display = 'none';
        loginScreen.style.display = 'grid';
        appContainer.style.display = 'none';
        showLoginError('Access Denied: You do not have administrator privileges.');
      }
    } catch (error) {
      console.error('Error checking admin status:', error);
      await auth.signOut();
      loadingScreen.style.display = 'none';
      loginScreen.style.display = 'grid';
      showLoginError('Error verifying privileges. Please try again.');
    }
  } else {
    // Logged out
    loadingScreen.style.display = 'none';
    loginScreen.style.display = 'grid';
    appContainer.style.display = 'none';
  }
});

async function handleLogin() {
  const email    = document.getElementById('login-email').value.trim();
  const password = document.getElementById('login-password').value;
  const errorEl  = document.getElementById('login-error');
  const btn      = document.getElementById('login-btn');

  if (!email || !password) {
    showLoginError('Please enter both email and password.');
    return;
  }

  btn.disabled = true;
  btn.textContent = 'Signing in...';
  errorEl.style.display = 'none';

  try {
    await auth.signInWithEmailAndPassword(email, password);
    // onAuthStateChanged will handle the UI switch
  } catch (error) {
    console.error('Login error:', error);
    showLoginError(error.message);
  } finally {
    btn.disabled = false;
    btn.textContent = 'Sign In';
  }
}

function handleLogout() {
  if (confirm('Are you sure you want to log out?')) {
    auth.signOut();
  }
}

function showLoginError(msg) {
  const errorEl = document.getElementById('login-error');
  errorEl.textContent = msg;
  errorEl.style.display = 'block';
}

// ── Data Fetching ─────────────────────────────────────────────────────────────

async function initDashboard() {
  // Setup real-time listeners
  db.collection('products').onSnapshot(snapshot => {
    products = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    updateUI('products');
  });
  loadNotificationHistory();


  db.collection('retailers').onSnapshot(snapshot => {
    retailers = snapshot.docs.map(doc => normalizeRetailerRecord({ id: doc.id, ...doc.data() }));
    updateUI('retailers');
  });

  db.collection('prices').onSnapshot(snapshot => {
    prices = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    updateUI('prices');
  });

  db.collection('users').onSnapshot(snapshot => {
    users = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    updateUI('users');
  });
}

function updateUI(type) {
  // Refresh current page if it matches the data type
  const activePage = document.querySelector('.nav-item.active').dataset.page;
  
  // Dashboard always needs updates
  renderDashboardStats();

  if (activePage === 'dashboard') renderDashboard();
  if (activePage === 'products') renderProducts();
  if (activePage === 'prices') renderPrices();
  if (activePage === 'retailers') renderRetailers();
  if (activePage === 'users') renderUsers();
  if (activePage === 'analytics') renderAnalytics();
}

// ── Navigation ────────────────────────────────────────────────────────────────

function showPage(page, el) {
  document.querySelectorAll('.page').forEach(p => p.classList.remove('active'));
  document.querySelectorAll('.nav-item').forEach(n => n.classList.remove('active'));
  document.getElementById('page-' + page).classList.add('active');
  if (el) el.classList.add('active');
  
  document.getElementById('page-title').textContent =
    { dashboard:'Dashboard', notifications:'Notifications', products:'Products', prices:'Prices',
      retailers:'Retailers', users:'Users', analytics:'Analytics',
      scraper:'Scraper', settings:'Settings' }[page] || page;

  // Render immediately with local data
  const refreshMap = {
    notifications: renderNotifications,
    products:  renderProducts,
    prices:    renderPrices,
    retailers: renderRetailers,
    users:     renderUsers,
    analytics: renderAnalytics,
    dashboard: renderDashboard,
    scraper:   renderScraper,
  };
  if (refreshMap[page]) refreshMap[page]();
  
  // Close sidebar on mobile
  if (window.innerWidth <= 768) {
    document.getElementById('sidebar').classList.remove('open');
  }

  return false;
}

function toggleSidebar() {
  document.getElementById('sidebar').classList.toggle('open');
}

// ── Render: Dashboard ─────────────────────────────────────────────────────────

function renderDashboardStats() {
  document.getElementById('stat-products').textContent  = products.length;
  document.getElementById('stat-prices').textContent    = prices.length;
  document.getElementById('stat-retailers').textContent = retailers.length;
  document.getElementById('stat-users').textContent     = users.length;
}

function renderDashboard() {
  // Recent products (last 4)
  const tbody = document.getElementById('recent-products-body');
  const recent = [...products].sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0)).slice(0, 4);
  
  tbody.innerHTML = recent.map(p => `
    <tr>
      <td>${p.name}</td>
      <td>${p.brand || p.category || '—'}</td>
      <td>${p.productType || '—'}</td>
      <td><span class="badge-status badge-active">Active</span></td>
    </tr>`).join('');

  // Price summary (cheapest per product)
  const summaryEl = document.getElementById('price-summary-list');
  const featured = products.slice(0, 5);
  
  summaryEl.innerHTML = featured.map(p => {
    const productPrices = prices.filter(x => x.productId == p.id);
    if (!productPrices.length) return '';
    const cheapest = productPrices.reduce((a, b) => a.price < b.price ? a : b);
    const retailer = retailers.find(r => r.id == cheapest.retailerId)?.name || 'Retailer';
    
    return `<div class="price-row">
      <div><div class="price-product">${p.name}</div>
           <div class="price-retailer">${retailer}</div></div>
      <div class="price-amount">RM ${cheapest.price.toFixed(2)}</div>
    </div>`;
  }).join('');
}

// ── Render: Products ──────────────────────────────────────────────────────────

function renderProducts() {
  const tbody = document.getElementById('products-tbody');
  tbody.innerHTML = products.map(p => `
    <tr>
      <td style="font-family: monospace; font-size: 0.75rem; color: var(--text-3);">${p.id}</td>
      <td>
        <div style="display:flex; align-items:center; gap:12px;">
          <div style="width:40px; height:40px; background:var(--bg-2); border-radius:4px; display:grid; place-items:center; overflow:hidden;">
            ${p.imageUrl ? `<img src="${p.imageUrl}" style="width:100%; height:100%; object-fit:contain" />` : '📦'}
          </div>
          <div>
            <div style="font-weight:700">${p.name}</div>
            <div style="font-size:.75rem; color:var(--text-3)">${p.description || p.desc || ''}</div>
          </div>
        </div>
      </td>
      <td>${p.category || '—'}</td>
      <td>${p.productType || '—'}</td>
      <td>
        <button class="action-btn edit"   onclick="openEditProductModal('${p.id}')">✏ Edit</button>
        <button class="action-btn delete" onclick="deleteProduct('${p.id}')">🗑 Delete</button>
      </td>
    </tr>`).join('');
}

async function addProduct() {
  const name = document.getElementById('new-product-name').value;
  const desc = document.getElementById('new-product-desc').value;
  const brand = document.getElementById('new-product-brand').value;
  const type = document.getElementById('new-product-type').value;
  const imageUrl = document.getElementById('new-product-image').value;

  if (!name || !desc) return showToast('❌ Please fill all fields');

  try {
    const newDoc = await db.collection('products').add({
      name,
      description: desc,
      category: brand,
      productType: type,
      imageUrl: imageUrl || '',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    await newDoc.update({ id: newDoc.id });

    closeModal('add-product-modal');
    document.getElementById('new-product-name').value = '';
    document.getElementById('new-product-desc').value = '';
    document.getElementById('new-product-image').value = '';
    showToast('✅ Product added!');
  } catch (e) {
    showToast('❌ Error adding product: ' + e.message);
  }
}

async function openEditProductModal(id) {
  const p = products.find(x => x.id === id);
  if (!p) return;

  document.getElementById('edit-product-id').value = id;
  document.getElementById('edit-product-name').value = p.name;
  document.getElementById('edit-product-desc').value = p.description || p.desc || '';
  document.getElementById('edit-product-brand').value = p.category || p.brand || '';
  document.getElementById('edit-product-type').value = p.productType || '';
  document.getElementById('edit-product-image').value = p.imageUrl || '';
  
  openModal('edit-product-modal');
}

async function saveEditProduct() {
  const id = document.getElementById('edit-product-id').value;
  const name = document.getElementById('edit-product-name').value;
  const desc = document.getElementById('edit-product-desc').value;
  const brand = document.getElementById('edit-product-brand').value;
  const type = document.getElementById('edit-product-type').value;
  const imageUrl = document.getElementById('edit-product-image').value;

  try {
    await db.collection('products').doc(id).update({
      name,
      description: desc,
      category: brand,
      productType: type,
      imageUrl: imageUrl || '',
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    closeModal('edit-product-modal');
    showToast('✅ Product updated!');
  } catch (e) {
    showToast('❌ Error updating product: ' + e.message);
  }
}

async function deleteProduct(id) {
  if (!confirm('Delete this product? Related prices will remain (cleanup required).')) return;
  try {
    await db.collection('products').doc(id).delete();
    showToast('🗑 Product deleted.');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

// ── Render: Prices ────────────────────────────────────────────────────────────

function renderPrices() {
  const tbody = document.getElementById('prices-tbody');
  
  // Update the product select in add price modal
  const prodSelect = document.getElementById('new-price-product');
  prodSelect.innerHTML = products.map(p => `<option value="${p.id}">${p.name}</option>`).join('');

  // Update the retailer select
  const retSelect = document.getElementById('new-price-retailer');
  retSelect.innerHTML = retailers.map(r => `<option value="${r.id}">${r.name}</option>`).join('');

  tbody.innerHTML = prices.map(p => {
    const productName  = products.find(prod => prod.id == p.productId)?.name || 'Unknown';
    const retailerName = retailers.find(ret => ret.id == p.retailerId)?.name || 'Unknown';
    const updatedDate  = p.updatedAt ? p.updatedAt.toDate().toLocaleDateString() : '—';
    
    return `
    <tr>
      <td style="font-family: monospace; font-size: 0.75rem; color: var(--text-3);">${p.id}</td>
      <td>${productName}</td>
      <td>${retailerName}</td>
      <td><strong style="color:var(--green-700)">RM ${p.price.toFixed(2)}</strong></td>
      <td style="color:var(--text-2);font-size:.82rem">${updatedDate}</td>
      <td>
        <button class="action-btn edit" onclick="openEditPriceModal('${p.id}')">✏ Edit</button>
        <button class="action-btn delete" onclick="deletePrice('${p.id}')">🗑 Delete</button>
      </td>
    </tr>`;
  }).join('');
}

async function addPrice() {
  const productId  = document.getElementById('new-price-product').value;
  const retailerId = document.getElementById('new-price-retailer').value;
  const price      = parseFloat(document.getElementById('new-price-value').value);

  if (isNaN(price) || price <= 0) { showToast('Enter a valid price.'); return; }

  try {
    const newDoc = await db.collection('prices').add({
      productId,
      retailerId,
      price,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    await newDoc.update({ id: newDoc.id });
    
    closeModal('add-price-modal');
    document.getElementById('new-price-value').value = '';
    showToast('✅ Price entry added!');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

async function openEditPriceModal(id) {
  const p = prices.find(x => x.id === id);
  if (!p) return;

  document.getElementById('edit-price-id').value = id;
  
  const prodSelect = document.getElementById('edit-price-product');
  prodSelect.innerHTML = products.map(x => `<option value="${x.id}" ${x.id == p.productId ? 'selected' : ''}>${x.name}</option>`).join('');
  
  const retSelect = document.getElementById('edit-price-retailer');
  retSelect.innerHTML = retailers.map(x => `<option value="${x.id}" ${x.id == p.retailerId ? 'selected' : ''}>${x.name}</option>`).join('');
  
  document.getElementById('edit-price-value').value = p.price;
  
  openModal('edit-price-modal');
}

async function saveEditPrice() {
  const id = document.getElementById('edit-price-id').value;
  const productId = document.getElementById('edit-price-product').value;
  const retailerId = document.getElementById('edit-price-retailer').value;
  const price = parseFloat(document.getElementById('edit-price-value').value);

  if (isNaN(price)) {
    showToast('❌ Please enter a valid price');
    return;
  }

  try {
    await db.collection('prices').doc(id).update({
      productId,
      retailerId,
      price,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    closeModal('edit-price-modal');
    showToast('✅ Price updated!');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

async function deletePrice(id) {
  if (!confirm('Delete this price entry?')) return;
  try {
    await db.collection('prices').doc(id).delete();
    showToast('🗑 Price deleted.');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

// ── Render: Retailers ─────────────────────────────────────────────────────────

function renderRetailers() {
  const grid = document.getElementById('retailers-grid');
  
  if (retailers.length === 0) {
    grid.innerHTML = `
      <div style="grid-column: 1/-1; text-align: center; padding: 60px; background: var(--card); border-radius: var(--radius); border: 1px dashed var(--border);">
        <div style="font-size: 3rem; margin-bottom: 16px;">🏢</div>
        <h3 style="color: var(--text);">No retailers found</h3>
        <p style="color: var(--text-2); margin-bottom: 20px;">Your database is empty. Start by adding store partners.</p>
        <button class="btn-primary" onclick="openModal('add-retailer-modal')">+ Add First Retailer</button>
      </div>`;
    return;
  }

  grid.innerHTML = retailers.map(r => {
    const isUrl = r.icon && (r.icon.startsWith('http') || r.icon.startsWith('assets/'));
    const logoHtml = isUrl ? `<img src="${r.icon}" style="width:100%;height:100%;object-fit:contain" />` : (r.icon || '🏪');
    
    return `
    <div class="retailer-card">
      <div class="retailer-icon">${logoHtml}</div>
      <div>
        <div class="retailer-name">${r.name}</div>
        <a href="${r.website}" target="_blank" class="retailer-url">${r.website}</a>
      </div>
      <div class="retailer-meta">${prices.filter(p => p.retailerId == r.id).length} price entries</div>
      <div class="retailer-actions">
        <button class="action-btn edit"   onclick="openEditRetailerModal('${r.id}')">✏ Edit</button>
        <button class="action-btn delete" onclick="deleteRetailer('${r.id}')">🗑 Delete</button>
      </div>
    </div>`;
  }).join('');
}

async function addRetailer() {
  const name = document.getElementById('new-retailer-name').value.trim();
  const url  = document.getElementById('new-retailer-url').value.trim();
  const icon = document.getElementById('new-retailer-icon').value.trim();
  if (!name) { showToast('Enter a retailer name.'); return; }

  try {
    const newDoc = await db.collection('retailers').add({
      name,
      website: url || '#',
      icon: icon || '🏪',
      logoUrl: icon || '',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    await newDoc.update({ id: newDoc.id });

    closeModal('add-retailer-modal');
    document.getElementById('new-retailer-name').value = '';
    document.getElementById('new-retailer-url').value  = '';
    document.getElementById('new-retailer-icon').value = '';
    showToast('✅ Retailer added!');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

async function openEditRetailerModal(id) {
  const r = retailers.find(x => x.id == id);
  if (!r) return;

  document.getElementById('edit-retailer-id').value = id;
  document.getElementById('edit-retailer-name').value = r.name;
  document.getElementById('edit-retailer-url').value = r.website || '';
  document.getElementById('edit-retailer-icon').value = r.icon || '';
  
  openModal('edit-retailer-modal');
}

async function saveEditRetailer() {
  const id = document.getElementById('edit-retailer-id').value;
  const name = document.getElementById('edit-retailer-name').value;
  const url = document.getElementById('edit-retailer-url').value;
  const icon = document.getElementById('edit-retailer-icon').value;

  if (!name.trim()) {
    showToast('❌ Retailer name is required');
    return;
  }

  try {
    await db.collection('retailers').doc(id).update({
      name: name.trim(),
      website: url.trim(),
      icon: icon.trim() || '🏪',
      logoUrl: icon.trim() || ''
    });
    closeModal('edit-retailer-modal');
    showToast('✅ Retailer updated!');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

async function deleteRetailer(id) {
  if (!confirm('Delete this retailer?')) return;
  try {
    await db.collection('retailers').doc(id).delete();
    showToast('🗑 Retailer deleted.');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

// ── Render: Users ─────────────────────────────────────────────────────────────

function renderUsers() {
  const tbody = document.getElementById('users-tbody');
  tbody.innerHTML = users.map(u => {
    const joinedDate = u.createdAt ? u.createdAt.toDate().toLocaleDateString() : '—';
    
    // Determine role and badge
    let roleText = 'User';
    let badgeClass = 'badge-active';
    let actionButtons = '';
    
    if (u.isSuperAdmin) {
      roleText = 'Super Admin';
      badgeClass = 'badge-super-admin';
      actionButtons = `
        <button class="action-btn edit" onclick="changeRole('${u.id}', 'admin')">
          👤 Demote to Admin
        </button>
      `;
    } else if (u.isAdmin) {
      roleText = 'Admin';
      badgeClass = 'badge-admin';
      actionButtons = `
        <button class="action-btn edit" onclick="changeRole('${u.id}', 'super')">
          🌟 Promote to Super
        </button>
        <button class="action-btn edit" onclick="changeRole('${u.id}', 'user')">
          👤 Demote to User
        </button>
      `;
    } else {
      roleText = 'User';
      badgeClass = 'badge-active';
      actionButtons = `
        <button class="action-btn edit" onclick="changeRole('${u.id}', 'admin')">
          👑 Promote to Admin
        </button>
      `;
    }

    return `
    <tr>
      <td style="font-family: monospace; font-size: 0.75rem; color: var(--text-3);">${u.id}</td>
      <td><strong>${u.name || 'Anonymous'}</strong></td>
      <td style="color:var(--text-2)">${u.email}</td>
      <td><span class="badge-status ${badgeClass}">${roleText}</span></td>
      <td style="color:var(--text-2);font-size:.82rem">${joinedDate}</td>
      <td>
        ${actionButtons}
        <button class="action-btn delete" onclick="deleteUser('${u.id}')">
          🗑 Remove
        </button>
      </td>
    </tr>`;
  }).join('');
}

async function changeRole(userId, newRole) {
  let updateFields = {};
  if (newRole === 'super') {
    updateFields = { isAdmin: true, isSuperAdmin: true };
  } else if (newRole === 'admin') {
    updateFields = { isAdmin: true, isSuperAdmin: false };
  } else {
    updateFields = { isAdmin: false, isSuperAdmin: false };
  }

  const confirmMsg = `Are you sure you want to change this user's role to ${newRole.toUpperCase()}?`;
  if (!confirm(confirmMsg)) return;

  try {
    await db.collection('users').doc(userId).update({
      ...updateFields,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast(`✅ User role updated to ${newRole}!`);
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

async function deleteUser(userId) {
  if (!confirm('Are you sure you want to remove this user from the system? This action cannot be undone.')) return;

  try {
    await db.collection('users').doc(userId).delete();
    showToast('🗑 User removed successfully!');
  } catch (e) {
    showToast('❌ Error: ' + e.message);
  }
}

// ── Render: Analytics ─────────────────────────────────────────────────────────

function renderAnalytics() {
  if (!products.length) return;

  const renderBar = (containerId, productName) => {
    const el = document.getElementById(containerId);
    if (!el) return;
    
    const product = products.find(p => p.name === productName);
    if (!product) { el.innerHTML = '<p>Product not found</p>'; return; }
    
    const productPrices = prices.filter(p => p.productId == product.id);
    if (!productPrices.length) { el.innerHTML = '<p>No price data</p>'; return; }
    
    const maxPrice = Math.max(...productPrices.map(p => p.price));
    el.innerHTML = productPrices.map(p => {
      const retailer = retailers.find(r => r.id == p.retailerId)?.name || 'Retailer';
      const pct = ((p.price / maxPrice) * 100).toFixed(1);
      return `<div class="bar-item">
        <div class="bar-label"><span>${retailer}</span><span>RM ${p.price.toFixed(2)}</span></div>
        <div class="bar-track"><div class="bar-fill" style="width:${pct}%"></div></div>
      </div>`;
    }).join('');
  };
  
  renderBar('chart-milo',  'Milo Activ-Go');
  renderBar('chart-maggi', 'Maggi Noodles');

  // Brand count
  const brandCounts = {};
  products.forEach(p => { 
    const b = p.category || p.brand || 'Other';
    brandCounts[b] = (brandCounts[b] || 0) + 1; 
  });
  const brandColors = ['#4caf50','#1565c0','#f57f17','#6a1b9a','#c62828'];
  document.getElementById('chart-brands').innerHTML =
    Object.entries(brandCounts).map(([name, count], i) => `
      <div class="donut-item">
        <div class="donut-dot" style="background:${brandColors[i % brandColors.length]}"></div>
        <span class="donut-name">${name}</span>
        <span class="donut-count">${count}</span>
      </div>`).join('');

  // Type count
  const typeCounts = {};
  products.forEach(p => { 
    const t = p.productType || 'Other';
    typeCounts[t] = (typeCounts[t] || 0) + 1; 
  });
  const typeColors = ['#0277bd','#e65100','#558b2f','#4527a0'];
  document.getElementById('chart-types').innerHTML =
    Object.entries(typeCounts).map(([name, count], i) => `
      <div class="donut-item">
        <div class="donut-dot" style="background:${typeColors[i % typeColors.length]}"></div>
        <span class="donut-name">${name}</span>
        <span class="donut-count">${count}</span>
      </div>`).join('');
}

// ── UI Helpers ────────────────────────────────────────────────────────────────

function filterTable(tableId, query) {
  const rows = document.querySelectorAll(`#${tableId} tbody tr`);
  const q = query.toLowerCase();
  rows.forEach(row => {
    row.style.display = row.textContent.toLowerCase().includes(q) ? '' : 'none';
  });
}

function filterByColumn(tableId, colIndex, value) {
  const rows = document.querySelectorAll(`#${tableId} tbody tr`);
  rows.forEach(row => {
    const cell = row.cells[colIndex];
    if (!value || (cell && cell.textContent.trim() === value)) {
      row.style.display = '';
    } else {
      row.style.display = 'none';
    }
  });
}

function handleGlobalSearch() {
  const q = document.getElementById('globalSearch').value;
  if (!q) return;
  showPage('products', document.querySelector('[data-page="products"]'));
  filterTable('products-table', q);
}

function openModal(id)  { document.getElementById(id).classList.add('open'); }
function closeModal(id) { document.getElementById(id).classList.remove('open'); }
function closeModalOutside(e, id) { if (e.target.id === id) closeModal(id); }

function readNotificationForm() {
  return {
    type: document.getElementById('notification-type').value,
    topic: document.getElementById('notification-topic').value.trim(),
    title: document.getElementById('notification-title').value.trim(),
    body: document.getElementById('notification-body').value.trim(),
    route: document.getElementById('notification-route').value.trim(),
    productId: document.getElementById('notification-product-id').value.trim(),
    productName: document.getElementById('notification-product-name').value.trim(),
    retailer: document.getElementById('notification-retailer').value.trim(),
    oldPrice: document.getElementById('notification-old-price').value.trim(),
    newPrice: document.getElementById('notification-new-price').value.trim(),
    budgetId: document.getElementById('notification-budget-id').value.trim(),
    spent: document.getElementById('notification-spent').value.trim(),
    limit: document.getElementById('notification-limit').value.trim(),
    listId: document.getElementById('notification-list-id').value.trim(),
    listName: document.getElementById('notification-list-name').value.trim(),
  };
}

function buildNotificationPayload(fields) {
  const payload = {
    topic: fields.topic,
    notification: {
      title: fields.title,
      body: fields.body,
    },
    data: {
      type: fields.type,
      route: fields.route || '/notifications',
      productId: fields.productId,
      productName: fields.productName,
      retailer: fields.retailer,
      oldPrice: fields.oldPrice,
      newPrice: fields.newPrice,
      budgetId: fields.budgetId,
      spent: fields.spent,
      limit: fields.limit,
      listId: fields.listId,
      listName: fields.listName,
    },
  };

  Object.keys(payload.data).forEach(key => {
    if (!payload.data[key]) delete payload.data[key];
  });

  return payload;
}

async function copyPayloadToClipboard(payload) {
  const pretty = JSON.stringify(payload, null, 2);
  if (navigator.clipboard?.writeText) {
    await navigator.clipboard.writeText(pretty);
    return;
  }

  const textarea = document.createElement('textarea');
  textarea.value = pretty;
  textarea.style.position = 'fixed';
  textarea.style.opacity = '0';
  document.body.appendChild(textarea);
  textarea.focus();
  textarea.select();
  document.execCommand('copy');
  document.body.removeChild(textarea);
}

async function submitNotification() {
  const fields = readNotificationForm();

  if (!fields.title || !fields.body) {
    showToast('❌ Title and body are required');
    return;
  }

  if (!fields.topic) {
    showToast('❌ Select a topic');
    return;
  }

  const payload = buildNotificationPayload(fields);

  try {
    // 1. Copy to clipboard as a developer fallback
    await copyPayloadToClipboard(payload);

    // 2. Write to Firestore to trigger backend Cloud Function
    await db.collection('notification_requests').add({
      ...payload,
      status: 'pending',
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });

    pushNotificationHistory({
      at: new Date().toISOString(),
      type: fields.type,
      title: fields.title,
      status: 'sent',
      channel: 'Cloud Function',
      target: fields.topic,
      source: 'manual',
    });

    showToast('🚀 Notification sent via Cloud Function!');
  } catch (error) {
    pushNotificationHistory({
      at: new Date().toISOString(),
      type: fields.type,
      title: fields.title,
      status: 'failed',
      channel: 'Cloud Function',
      target: fields.topic,
      source: 'manual',
    });
    showToast('❌ Failed to send: ' + error.message);
  }
}

function setNotificationTemplate(template) {
  const presets = {
    price_drop: {
      type: 'price_drop',
      topic: 'price_alerts',
      title: '🎉 Price Drop! Milo Activ-Go',
      body: 'Mydin: RM11.99 (was RM12.50)',
      route: '/product-details',
      productId: 'milo-001',
      productName: 'Milo Activ-Go',
      retailer: 'Mydin',
      oldPrice: '12.50',
      newPrice: '11.99',
    },
    budget_alert: {
      type: 'budget_alert',
      topic: 'budget_alerts',
      title: '⚠️ Budget Warning',
      body: 'You have used 80% of your RM500.00 budget.',
      route: '/budget',
      budgetId: 'budget-001',
      spent: '400.00',
      limit: '500.00',
    },
    shopping_reminder: {
      type: 'shopping_reminder',
      topic: 'shopping_reminders',
      title: '🛒 Shopping Reminder',
      body: 'Don\'t forget to check your weekend shopping list.',
      route: '/shopping-lists',
      listId: 'list-001',
      listName: 'Weekend Groceries',
    },
    weekly_digest: {
      type: 'weekly_digest',
      topic: 'weekly_digest',
      title: '📬 Weekly Digest',
      body: '3 items dropped this week — estimated savings RM12.40. Top: Milo Activ-Go (RM12.50 → RM11.99).',
      route: '/notifications',
    },
  };

  const preset = presets[template];
  if (!preset) return;

  Object.entries(preset).forEach(([key, value]) => {
    const field = document.getElementById(`notification-${key.replace(/([A-Z])/g, '-$1').toLowerCase()}`);
    if (field) field.value = value;
  });
}

async function sendQuickNotification(template) {
  setNotificationTemplate(template);
  await submitNotification();
}

window.sendQuickNotification = sendQuickNotification;
window.submitNotification = submitNotification;
window.renderNotifications = renderNotifications;
window.changeRole = changeRole;
window.deleteUser = deleteUser;

function toggleDarkMode() { document.body.classList.toggle('dark'); }

function toggleCompact() {
  const s = document.getElementById('sidebar');
  s.classList.toggle('compact');
}

function showToast(msg) {
  const t = document.getElementById('toast');
  t.textContent = msg;
  t.classList.add('show');
  setTimeout(() => t.classList.remove('show'), 3000);
}

async function seedDatabase() {
  if (!confirm('This will populate your database with initial mock data. Continue?')) return;

  const mockRetailers = [
    { 
      id: '1', 
      name: 'Mydin',   
      website: 'https://mydin.com.my',  
      icon: 'https://www.mydin.com.my/img/mydin-logo.png',
      logoUrl: 'https://www.mydin.com.my/img/mydin-logo.png' 
    },
    { 
      id: '2', 
      name: 'myAEON2go',   
      website: 'https://myaeon2go.com',  
      icon: 'https://thumbor.asia-southeast1.aeon-my-prod.e.spresso.com/unsafe/web2-assets.myboxed.com.my/public/images/32x25_optimized.png',
      logoUrl: 'https://thumbor.asia-southeast1.aeon-my-prod.e.spresso.com/unsafe/web2-assets.myboxed.com.my/public/images/32x25_optimized.png'
    },
    { 
      id: '5', 
      name: "Lotus's", 
      website: 'https://www.lotuss.com.my/en', 
      icon: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Lotus%27s_Logo.svg/1200px-Lotus%27s_Logo.svg.png',
      logoUrl: 'https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Lotus%27s_Logo.svg/1200px-Lotus%27s_Logo.svg.png'
    },
  ];

  const mockProducts = [
    { 
      id: '1', 
      name: 'Milo Activ-Go', 
      desc: 'Chocolate malt drink powder - 400g', 
      brand: 'Nestlé', 
      type: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1550989460-0adf9ea622e2?q=80&w=200&auto=format&fit=crop'
    },
    { 
      id: '2', 
      name: 'Maggi Noodles',  
      desc: 'Instant noodles - 5 packs',         
      brand: 'Nestlé', 
      type: 'Instant Noodles',
      imageUrl: 'https://images.unsplash.com/photo-1612927329915-406b88a49df2?q=80&w=200&auto=format&fit=crop'
    },
    { 
      id: '3', 
      name: 'Teh Tarik Mix',  
      desc: 'Instant tea mix - 300g',            
      brand: 'Aik Cheong', 
      type: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1544787210-2211d403ef8c?q=80&w=200&auto=format&fit=crop'
    },
    { 
      id: '4', 
      name: 'Beras Wangi',    
      desc: 'Jasmine rice - 5kg',                
      brand: 'Faiza',  
      type: 'Rice & Grains',
      imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?q=80&w=200&auto=format&fit=crop'
    },
    { 
      id: '6', 
      name: 'Nescafé Gold',   
      desc: 'Premium instant coffee - 200g',     
      brand: 'Nestlé', 
      type: 'Drinks',
      imageUrl: 'https://images.unsplash.com/photo-1559056199-641a0ac8b55e?q=80&w=200&auto=format&fit=crop'
    },
    { 
      id: '7', 
      name: 'Sunlight Dishwashing Liquid', 
      desc: 'Dishwashing liquid - 800ml', 
      brand: 'Unilever', 
      type: 'Household Cleaning',
      imageUrl: 'https://images.unsplash.com/photo-1584622781564-1d987f7333c1?q=80&w=200&auto=format&fit=crop'
    },
  ];

  const mockPrices = [
    { productId: '1', retailerId: '1', price: 12.50 },
    { productId: '1', retailerId: '2', price: 11.99 },
    { productId: '1', retailerId: '5', price: 12.30 },
    { productId: '2', retailerId: '1', price: 4.50 },
    { productId: '2', retailerId: '2', price: 4.20 },
    { productId: '2', retailerId: '5', price: 4.60 },
    { productId: '3', retailerId: '1', price: 8.90 },
    { productId: '4', retailerId: '1', price: 22.80 },
    { productId: '6', retailerId: '1', price: 18.50 },
    { productId: '7', retailerId: '1', price: 6.80 },
  ];

  showToast('🌱 Seeding database...');

  try {
    const batch = db.batch();

    // Seed Retailers
    mockRetailers.forEach(r => {
      const ref = db.collection('retailers').doc(r.id);
      batch.set(ref, { 
        ...r, 
        createdAt: firebase.firestore.FieldValue.serverTimestamp() 
      });
    });

    // Seed Products
    mockProducts.forEach(p => {
      const ref = db.collection('products').doc(p.id);
      batch.set(ref, { 
        id: p.id,
        name: p.name, 
        description: p.desc, 
        category: p.brand, 
        productType: p.type,
        imageUrl: p.imageUrl,
        createdAt: firebase.firestore.FieldValue.serverTimestamp() 
      });
    });

    // Seed Prices
    mockPrices.forEach((p, i) => {
      const id = `price_${i}`;
      const ref = db.collection('prices').doc(id);
      batch.set(ref, { 
        id,
        ...p, 
        updatedAt: firebase.firestore.FieldValue.serverTimestamp() 
      });
    });

    await batch.commit();
    showToast('✅ Database seeded successfully!');
  } catch (e) {
    console.error(e);
    showToast('❌ Error seeding database: ' + e.message);
  }
}


// ── Scraper Scheduler ─────────────────────────────────────────────────────────

const FREQUENCIES = {
  'Every 6 Hours':  6 * 3600,
  'Every 12 Hours': 12 * 3600,
  'Daily':          24 * 3600,
  'Weekly':         7 * 24 * 3600,
};

// Default scheduler state (persisted to localStorage)
function getScraperJobs() {
  try {
    const saved = localStorage.getItem('smartshopper_scraper_jobs');
    if (saved) return JSON.parse(saved);
  } catch(e) {}
  return [
    {
      id: 'job_mydin',
      retailerName: 'Mydin',
      targetUrl: 'https://mydin.com.my/grocery',
      frequency: 'Daily',
      scheduledTime: '02:00',
      lastRun: new Date(Date.now() - 6 * 3600 * 1000).toISOString(),
      status: 'idle',
      itemsScraped: 47,
    },
    {
      id: 'job_myaeon2go',
      retailerName: 'myAEON2go',
      targetUrl: 'https://myaeon2go.com',
      frequency: 'Every 12 Hours',
      scheduledTime: '08:00',
      lastRun: new Date(Date.now() - 11 * 3600 * 1000).toISOString(),
      status: 'idle',
      itemsScraped: 63,
    },
    {
      id: 'job_lotuss',
      retailerName: "Lotus's",
      targetUrl: 'https://www.lotuss.com.my/en',
      frequency: 'Every 6 Hours',
      scheduledTime: '06:00',
      lastRun: new Date(Date.now() - 2 * 3600 * 1000).toISOString(),
      status: 'error',
      itemsScraped: 0,
    },
  ];
}

function saveScraperJobs(jobs) {
  localStorage.setItem('smartshopper_scraper_jobs', JSON.stringify(jobs));
}

let scraperJobs = getScraperJobs();
let scraperLogEntries = [];

function nextRunTime(job) {
  const freqSec = FREQUENCIES[job.frequency] || 86400;
  const now = new Date();

  // If a specific time of day is set, find the next wall-clock occurrence
  // that is at least freqSec seconds after the last run.
  if (job.scheduledTime) {
    const [hh, mm] = job.scheduledTime.split(':').map(Number);
    // Build candidate = today at scheduledTime
    let candidate = new Date(now);
    candidate.setHours(hh, mm, 0, 0);

    // If the last run is known, the next run must be >= lastRun + freqSec
    const earliest = job.lastRun
      ? new Date(new Date(job.lastRun).getTime() + freqSec * 1000)
      : now;

    // Advance candidate by 1 day until it is >= earliest AND >= now
    while (candidate < earliest || candidate <= now) {
      candidate = new Date(candidate.getTime() + 86400 * 1000);
    }

    const diff = candidate - now;
    const totalMin = Math.floor(diff / 60000);
    const h = Math.floor(totalMin / 60);
    const m = totalMin % 60;
    const label = candidate.toLocaleDateString([], { weekday: 'short', month: 'short', day: 'numeric' });
    return `${label} ${job.scheduledTime} (in ${h > 0 ? h + 'h ' : ''}${m}m)`;
  }

  // Fallback: frequency-only (no specific time)
  if (!job.lastRun) return 'Not scheduled';
  const next = new Date(new Date(job.lastRun).getTime() + freqSec * 1000);
  if (next <= now) return '⚡ Overdue';
  const diffF = next - now;
  const hF = Math.floor(diffF / 3600000);
  const mF = Math.floor((diffF % 3600000) / 60000);
  return hF > 0 ? `in ${hF}h ${mF}m` : `in ${mF}m`;
}

function formatLastRun(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  const now = new Date();
  const diff = now - d;
  const m = Math.floor(diff / 60000);
  const h = Math.floor(diff / 3600000);
  if (m < 1)  return 'Just now';
  if (m < 60) return `${m}m ago`;
  if (h < 24) return `${h}h ago`;
  return d.toLocaleDateString();
}

function statusBadge(status) {
  const map = {
    idle:    '<span style="background:#e8f5e9;color:#2e7d32;padding:2px 10px;border-radius:20px;font-size:.72rem;font-weight:700">● Idle</span>',
    running: '<span style="background:#e3f2fd;color:#1565c0;padding:2px 10px;border-radius:20px;font-size:.72rem;font-weight:700;animation:pulse 1s infinite">⚙ Running</span>',
    success: '<span style="background:#e8f5e9;color:#2e7d32;padding:2px 10px;border-radius:20px;font-size:.72rem;font-weight:700">✓ Success</span>',
    error:   '<span style="background:#ffebee;color:#c62828;padding:2px 10px;border-radius:20px;font-size:.72rem;font-weight:700">✕ Error</span>',
  };
  return map[status] || map['idle'];
}

function renderScraper() {
  const tbody = document.getElementById('scraper-tbody');
  if (!tbody) return;

  const running = scraperJobs.filter(j => j.status === 'running').length;
  document.getElementById('s-scheduled').textContent = scraperJobs.length;
  document.getElementById('s-running').textContent   = running;

  tbody.innerHTML = scraperJobs.map(job => `
    <tr id="row-${job.id}">
      <td><strong>${job.retailerName}</strong></td>
      <td style="font-size:.78rem;color:var(--text-2);max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">
        <a href="${job.targetUrl}" target="_blank" style="color:var(--green-700)">${job.targetUrl}</a></td>
      <td>
        <select onchange="updateFrequency('${job.id}', this.value)"
          style="border:1px solid var(--border);border-radius:6px;padding:4px 8px;font-size:.8rem;background:var(--bg);color:var(--text)">
          ${Object.keys(FREQUENCIES).map(f =>
            `<option ${f === job.frequency ? 'selected' : ''}>${f}</option>`
          ).join('')}
        </select>
      </td>
      <td>
        <input type="time" value="${job.scheduledTime || '00:00'}"
          onchange="updateScheduledTime('${job.id}', this.value)"
          style="border:1.5px solid var(--green-500);border-radius:6px;padding:5px 8px;font-size:.88rem;font-weight:600;background:var(--bg);color:var(--text);cursor:pointer;min-width:110px" />
      </td>
      <td style="font-size:.82rem;color:var(--text-2)">${formatLastRun(job.lastRun)}</td>
      <td style="font-size:.76rem;color:var(--green-700);font-weight:500;max-width:190px">${nextRunTime(job)}</td>
      <td>${statusBadge(job.status)}</td>
      <td style="text-align:center;font-weight:700">${job.itemsScraped > 0 ? job.itemsScraped : '—'}</td>
      <td>
        <button class="action-btn edit" onclick="runScraper('${job.id}')"
          ${job.status === 'running' ? 'disabled' : ''}>
          ${job.status === 'running' ? '⏳ Running…' : '▶ Run Now'}
        </button>
      </td>
    </tr>
  `).join('');

  renderLog();
}

function addLog(level, retailer, message) {
  const ts = new Date().toLocaleTimeString();
  scraperLogEntries.unshift({ ts, level, retailer, message });
  if (scraperLogEntries.length > 200) scraperLogEntries.pop();
  renderLog();
}

function renderLog() {
  const el = document.getElementById('scraper-log');
  if (!el) return;
  const filter = document.getElementById('log-filter')?.value || '';
  const entries = filter ? scraperLogEntries.filter(e => e.level === filter) : scraperLogEntries;

  if (entries.length === 0) {
    el.innerHTML = '<span style="color:var(--text-3)">No log entries yet. Run a scraper to see activity.</span>';
    return;
  }

  const colors = { INFO: '#1565c0', SUCCESS: '#2e7d32', WARN: '#f57f17', ERROR: '#c62828' };
  const icons  = { INFO: 'ℹ', SUCCESS: '✓', WARN: '⚠', ERROR: '✕' };

  el.innerHTML = entries.map(e => `
    <div class="log-entry" data-level="${e.level}" style="margin-bottom:2px">
      <span style="color:var(--text-3)">[${e.ts}]</span>
      <span style="color:${colors[e.level]};font-weight:700;margin:0 6px">${icons[e.level]} ${e.level}</span>
      <span style="color:var(--text-2);margin-right:6px">[${e.retailer}]</span>
      <span style="color:var(--text)">${e.message}</span>
    </div>
  `).join('');
}

function filterLog() { renderLog(); }
function clearLog() { scraperLogEntries = []; renderLog(); }

function updateFrequency(jobId, freq) {
  const job = scraperJobs.find(j => j.id === jobId);
  if (!job) return;
  job.frequency = freq;
  saveScraperJobs(scraperJobs);
  addLog('INFO', job.retailerName, `Frequency updated to "${freq}" (next run recalculated)`);
  renderScraper();
  showToast(`✅ ${job.retailerName} frequency set to ${freq}`);
}

function updateScheduledTime(jobId, time) {
  const job = scraperJobs.find(j => j.id === jobId);
  if (!job) return;
  job.scheduledTime = time;
  saveScraperJobs(scraperJobs);
  addLog('INFO', job.retailerName, `Scheduled run time updated to ${time}`);
  renderScraper();
  showToast(`✅ ${job.retailerName} will run daily at ${time}`);
}

async function runScraper(jobId) {
  const job = scraperJobs.find(j => j.id === jobId);
  if (!job || job.status === 'running') return;

  job.status = 'running';
  renderScraper();
  document.getElementById('s-running').textContent =
    scraperJobs.filter(j => j.status === 'running').length;

  addLog('INFO', job.retailerName, `Scraping job started — target: ${job.targetUrl}`);
  addLog('INFO', job.retailerName, 'Sending HTTP GET request to retailer website…');

  // Simulate scraping steps with realistic delays
  const delay = ms => new Promise(res => setTimeout(res, ms));
  const totalItems = Math.floor(Math.random() * 30) + 20;
  const succeed = Math.random() > 0.15;

  await delay(800);
  addLog('INFO', job.retailerName, 'Connected. Parsing HTML document structure…');
  await delay(600);
  addLog('INFO', job.retailerName, 'Extracting product listing containers…');
  await delay(500);

  if (!succeed) {
    addLog('WARN', job.retailerName, 'Rate-limit detected (HTTP 429). Backing off 30s…');
    await delay(1000);
    addLog('ERROR', job.retailerName, 'Max retries exceeded. Scraping job FAILED.');
    job.status = 'error';
    job.itemsScraped = 0;
    const failed = parseInt(document.getElementById('s-failed').textContent) + 1;
    document.getElementById('s-failed').textContent = failed;
  } else {
    for (let i = 1; i <= 3; i++) {
      await delay(400);
      const batch = Math.ceil(totalItems * i / 3);
      addLog('INFO', job.retailerName, `Scraped ${batch}/${totalItems} product prices…`);
    }
    await delay(300);
    addLog('INFO', job.retailerName, `Writing ${totalItems} updated prices to Firestore…`);
    await delay(400);

    // Simulate writing to Firestore (update prices for known products)
    try {
      const retailerDoc = retailers.find(r => r.name === job.retailerName);
      if (retailerDoc && prices.length > 0) {
        const retailerPrices = prices.filter(p => p.retailerId == retailerDoc.id);
        if (retailerPrices.length > 0) {
          const randomPrice = retailerPrices[Math.floor(Math.random() * retailerPrices.length)];
          const newPrice = parseFloat((randomPrice.price * (0.95 + Math.random() * 0.10)).toFixed(2));
          await db.collection('prices').doc(randomPrice.id).update({
            price: newPrice,
            scrapedAt: firebase.firestore.FieldValue.serverTimestamp(),
            updatedAt: firebase.firestore.FieldValue.serverTimestamp()
          });
          addLog('SUCCESS', job.retailerName, `Updated price for product ID ${randomPrice.productId} → RM ${newPrice}`);
        }
      }
    } catch(e) {
      addLog('WARN', job.retailerName, 'Firestore write error (non-fatal): ' + e.message);
    }

    addLog('SUCCESS', job.retailerName, `Job completed. ${totalItems} prices updated in database.`);
    job.status = 'success';
    job.itemsScraped = totalItems;
    job.lastRun = new Date().toISOString();
    const completed = parseInt(document.getElementById('s-completed').textContent) + 1;
    document.getElementById('s-completed').textContent = completed;
  }

  saveScraperJobs(scraperJobs);
  renderScraper();
  showToast(succeed
    ? `✅ ${job.retailerName}: scraped ${totalItems} prices`
    : `❌ ${job.retailerName}: scraping failed`);
}

async function runAllScrapers() {
  if (!confirm('Run scraping for ALL retailers now?')) return;
  addLog('INFO', 'SYSTEM', '── Run All triggered by admin ──');
  for (const job of scraperJobs) {
    runScraper(job.id);
    await new Promise(res => setTimeout(res, 500));
  }
}

// Initialize log with seed entries
function initScraperLog() {
  const now = new Date();
  const ts = t => new Date(now - t).toLocaleTimeString();
  scraperLogEntries = [
    { ts: ts(1800000), level: 'SUCCESS', retailer: 'Mydin',   message: 'Job completed. 47 prices updated in database.' },
    { ts: ts(1801000), level: 'INFO',    retailer: 'Mydin',   message: 'Writing 47 updated prices to Firestore…' },
    { ts: ts(1802000), level: 'INFO',    retailer: 'Mydin',   message: 'Scraped 47/47 product prices…' },
    { ts: ts(3600000), level: 'ERROR',   retailer: "Lotus's", message: 'Max retries exceeded. Scraping job FAILED.' },
    { ts: ts(3601000), level: 'WARN',    retailer: "Lotus's", message: 'Rate-limit detected (HTTP 429). Backing off 30s…' },
    { ts: ts(3602000), level: 'INFO',    retailer: "Lotus's", message: 'Sending HTTP GET request to retailer website…' },
    { ts: ts(7200000), level: 'SUCCESS', retailer: 'myAEON2go',   message: 'Job completed. 63 prices updated in database.' },
    { ts: ts(7202000), level: 'INFO',    retailer: 'myAEON2go',   message: 'Scraping job started — target: https://myaeon2go.com' },
  ];
}

initScraperLog();

// ── Global Handlers ───────────────────────────────────────────────────────────

window.handleLogin = handleLogin;
window.handleLogout = handleLogout;
window.showPage = showPage;
window.toggleSidebar = toggleSidebar;
window.filterTable = filterTable;
window.filterByColumn = filterByColumn;
window.handleGlobalSearch = handleGlobalSearch;
window.openModal = openModal;
window.closeModal = closeModal;
window.closeModalOutside = closeModalOutside;
window.addProduct = addProduct;
window.openEditProductModal = openEditProductModal;
window.saveEditProduct = saveEditProduct;
window.deleteProduct = deleteProduct;
window.addPrice = addPrice;
window.openEditPriceModal = openEditPriceModal;
window.saveEditPrice = saveEditPrice;
window.deletePrice = deletePrice;
window.addRetailer = addRetailer;
window.openEditRetailerModal = openEditRetailerModal;
window.saveEditRetailer = saveEditRetailer;
window.deleteRetailer = deleteRetailer;
window.toggleAdmin = toggleAdmin;
window.seedDatabase = seedDatabase;
window.toggleDarkMode = toggleDarkMode;
window.toggleCompact = toggleCompact;
window.showToast = showToast;
window.renderScraper = renderScraper;
window.runScraper = runScraper;
window.runAllScrapers = runAllScrapers;
window.updateFrequency = updateFrequency;
window.updateScheduledTime = updateScheduledTime;
window.filterLog = filterLog;
window.clearLog = clearLog;
