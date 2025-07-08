// Admin Panel JavaScript
class AdminPanel {
    constructor() {
        this.apiKey = 'supersecretapikey123';
        this.socket = null;
        this.init();
    }

    init() {
        this.initNavigation();
        this.initSocketConnection();
        this.initDomainManagement();
        this.initApiKeyManagement();
        this.initApiTesting();
        this.loadDashboardStats();
        this.loadDomains();
        this.loadCurrentApiKey();
        this.updateSystemStatus();
    }

    // Navigation
    initNavigation() {
        const navItems = document.querySelectorAll('.nav-item');
        const pages = document.querySelectorAll('.page');

        navItems.forEach(item => {
            item.addEventListener('click', () => {
                const targetPage = item.dataset.page;
                
                // Update active nav item
                navItems.forEach(nav => nav.classList.remove('active'));
                item.classList.add('active');
                
                // Show target page
                pages.forEach(page => page.classList.remove('active'));
                document.getElementById(targetPage).classList.add('active');
                
                // Load page-specific data
                this.loadPageData(targetPage);
            });
        });
    }

    // Socket.IO Connection
    initSocketConnection() {
        this.socket = io();
        
        this.socket.on('connect', () => {
            console.log('Connected to server');
            this.updateConnectionStatus(true);
        });
        
        this.socket.on('disconnect', () => {
            console.log('Disconnected from server');
            this.updateConnectionStatus(false);
        });
        
        this.socket.on('new_mail', (mail) => {
            this.addEmailToMonitor(mail);
            this.updateEmailCount();
        });
    }

    updateConnectionStatus(connected) {
        const statusIndicator = document.querySelector('.status-indicator');
        if (connected) {
            statusIndicator.textContent = 'Online';
            statusIndicator.className = 'status-indicator online';
        } else {
            statusIndicator.textContent = 'Offline';
            statusIndicator.className = 'status-indicator offline';
        }
    }

    // Domain Management
    initDomainManagement() {
        const addBtn = document.getElementById('add-domain-btn');
        const refreshBtn = document.getElementById('refresh-domains');
        const domainInput = document.getElementById('new-domain');

        addBtn.addEventListener('click', () => this.addDomain());
        refreshBtn.addEventListener('click', () => this.loadDomains());
        
        domainInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.addDomain();
            }
        });
    }

    async addDomain() {
        const domainInput = document.getElementById('new-domain');
        const domain = domainInput.value.trim();
        
        if (!domain) {
            this.showMessage('Please enter a domain name', 'error');
            return;
        }
        
        if (!this.isValidDomain(domain)) {
            this.showMessage('Please enter a valid domain name', 'error');
            return;
        }

        try {
            const response = await fetch(`/admin/domains/add?key=${this.apiKey}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ domain })
            });

            if (response.ok) {
                this.showMessage(`Domain '${domain}' added successfully`, 'success');
                domainInput.value = '';
                this.loadDomains();
                this.updateDomainCount();
            } else {
                const error = await response.text();
                this.showMessage(`Error: ${error}`, 'error');
            }
        } catch (err) {
            this.showMessage(`Error adding domain: ${err.message}`, 'error');
        }
    }

    async deleteDomain(domain) {
        if (!confirm(`Are you sure you want to delete domain '${domain}'?`)) {
            return;
        }

        try {
            const response = await fetch(`/admin/domains/delete?key=${this.apiKey}`, {
                method: 'DELETE',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ domain })
            });

            if (response.ok) {
                this.showMessage(`Domain '${domain}' deleted successfully`, 'success');
                this.loadDomains();
                this.updateDomainCount();
            } else {
                const error = await response.text();
                this.showMessage(`Error: ${error}`, 'error');
            }
        } catch (err) {
            this.showMessage(`Error deleting domain: ${err.message}`, 'error');
        }
    }

    async loadDomains() {
        const container = document.getElementById('domains-container');
        container.innerHTML = '<div class="loading"></div>';

        try {
            const response = await fetch(`/admin/domains?key=${this.apiKey}`);
            if (response.ok) {
                const domains = await response.json();
                this.renderDomains(domains);
            } else {
                container.innerHTML = '<p style="color: #ff4444; padding: 20px;">Error loading domains</p>';
            }
        } catch (err) {
            container.innerHTML = '<p style="color: #ff4444; padding: 20px;">Error loading domains</p>';
        }
    }

    renderDomains(domains) {
        const container = document.getElementById('domains-container');
        
        if (domains.length === 0) {
            container.innerHTML = '<p style="color: #888; padding: 20px;">No domains configured</p>';
            return;
        }

        container.innerHTML = domains.map(domain => `
            <div class="domain-item">
                <div class="domain-name">
                    <i class="fas fa-globe"></i>
                    ${domain}
                </div>
                <button class="btn btn-danger" onclick="adminPanel.deleteDomain('${domain}')">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </div>
        `).join('');
    }

    // Dashboard Stats
    async loadDashboardStats() {
        try {
            const response = await fetch(`/admin/stats?key=${this.apiKey}`);
            if (response.ok) {
                const stats = await response.json();
                document.getElementById('total-emails').textContent = stats.totalEmails || 0;
                document.getElementById('total-domains').textContent = stats.totalDomains || 0;
                document.getElementById('active-users').textContent = stats.activeUsers || 0;
            }
        } catch (err) {
            console.error('Error loading stats:', err);
        }
    }

    async updateEmailCount() {
        try {
            const response = await fetch(`/admin/stats?key=${this.apiKey}`);
            if (response.ok) {
                const stats = await response.json();
                document.getElementById('total-emails').textContent = stats.totalEmails || 0;
            }
        } catch (err) {
            console.error('Error updating email count:', err);
        }
    }

    async updateDomainCount() {
        try {
            const response = await fetch(`/admin/stats?key=${this.apiKey}`);
            if (response.ok) {
                const stats = await response.json();
                document.getElementById('total-domains').textContent = stats.totalDomains || 0;
            }
        } catch (err) {
            console.error('Error updating domain count:', err);
        }
    }

    // Email Monitor
    addEmailToMonitor(mail) {
        const emailList = document.getElementById('email-list');
        const emailItem = document.createElement('div');
        emailItem.className = 'email-item';
        emailItem.innerHTML = `
            <div class="email-header">
                <span class="email-from">${mail.from}</span>
                <span class="email-date">${new Date(mail.date).toLocaleString()}</span>
            </div>
            <div class="email-subject">${mail.subject}</div>
            <div class="email-to">To: ${Array.isArray(mail.to) ? mail.to.join(', ') : mail.to}</div>
        `;
        
        emailList.insertBefore(emailItem, emailList.firstChild);
        
        // Keep only last 50 emails
        while (emailList.children.length > 50) {
            emailList.removeChild(emailList.lastChild);
        }
    }

    async loadRecentEmails() {
        try {
            const response = await fetch(`/admin/recent-emails?key=${this.apiKey}`);
            if (response.ok) {
                const emails = await response.json();
                const emailList = document.getElementById('email-list');
                emailList.innerHTML = emails.map(mail => `
                    <div class="email-item">
                        <div class="email-header">
                            <span class="email-from">${mail.from}</span>
                            <span class="email-date">${new Date(mail.date).toLocaleString()}</span>
                        </div>
                        <div class="email-subject">${mail.subject}</div>
                        <div class="email-to">To: ${Array.isArray(mail.to) ? mail.to.join(', ') : mail.to}</div>
                    </div>
                `).join('');
            }
        } catch (err) {
            console.error('Error loading recent emails:', err);
        }
    }

    // API Key Management
    initApiKeyManagement() {
        const showApiKeyBtn = document.getElementById('show-api-key');
        const updateApiKeyBtn = document.getElementById('update-api-key');
        const currentApiKeyInput = document.getElementById('current-api-key');
        const newApiKeyInput = document.getElementById('new-api-key');

        showApiKeyBtn.addEventListener('click', () => {
            if (currentApiKeyInput.type === 'password') {
                currentApiKeyInput.type = 'text';
                showApiKeyBtn.innerHTML = '<i class="fas fa-eye-slash"></i>';
            } else {
                currentApiKeyInput.type = 'password';
                showApiKeyBtn.innerHTML = '<i class="fas fa-eye"></i>';
            }
        });

        updateApiKeyBtn.addEventListener('click', () => this.updateApiKey());
        
        newApiKeyInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                this.updateApiKey();
            }
        });
    }

    async loadCurrentApiKey() {
        try {
            const response = await fetch(`/admin/current-api-key?key=${this.apiKey}`);
            if (response.ok) {
                const data = await response.json();
                document.getElementById('current-api-key').value = data.apiKey;
            }
        } catch (err) {
            console.error('Error loading current API key:', err);
        }
    }

    async updateApiKey() {
        const newApiKeyInput = document.getElementById('new-api-key');
        const newApiKey = newApiKeyInput.value.trim();
        
        if (!newApiKey) {
            this.showMessage('Please enter a new API key', 'error');
            return;
        }
        
        if (newApiKey.length < 8) {
            this.showMessage('API key must be at least 8 characters long', 'error');
            return;
        }

        try {
            const response = await fetch(`/admin/update-api-key?key=${this.apiKey}`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ newApiKey })
            });

            if (response.ok) {
                this.apiKey = newApiKey;
                document.getElementById('current-api-key').value = newApiKey;
                newApiKeyInput.value = '';
                this.showMessage('API key updated successfully', 'success');
            } else {
                const error = await response.text();
                this.showMessage(`Error: ${error}`, 'error');
            }
        } catch (err) {
            this.showMessage(`Error updating API key: ${err.message}`, 'error');
        }
    }

    // API Testing
    initApiTesting() {
        const testAllBtn = document.getElementById('test-all-apis');
        const clearResultsBtn = document.getElementById('clear-test-results');

        testAllBtn.addEventListener('click', () => this.testAllApis());
        clearResultsBtn.addEventListener('click', () => this.clearTestResults());
    }

    async testAllApis() {
        const resultsContainer = document.getElementById('api-test-results');
        resultsContainer.innerHTML = '<div class="loading"></div>';

        const apiEndpoints = [
            { name: 'Generate Random Email', method: 'GET', url: '/generate' },
            { name: 'Get Domains', method: 'GET', url: '/admin/domains' },
            { name: 'Get Statistics', method: 'GET', url: '/admin/stats' },
            { name: 'Get Recent Emails', method: 'GET', url: '/admin/recent-emails' },
            { name: 'Test Domain Add', method: 'POST', url: '/admin/domains/add', body: { domain: 'test-domain-temp.com' } },
            { name: 'Test Domain Delete', method: 'DELETE', url: '/admin/domains/delete', body: { domain: 'test-domain-temp.com' } }
        ];

        resultsContainer.innerHTML = '';

        for (const endpoint of apiEndpoints) {
            await this.testSingleApi(endpoint, resultsContainer);
            await new Promise(resolve => setTimeout(resolve, 500)); // Small delay between tests
        }
    }

    async testSingleApi(endpoint, container) {
        const resultDiv = document.createElement('div');
        resultDiv.className = 'test-result';
        resultDiv.innerHTML = `
            <div>
                <div class="test-endpoint">${endpoint.method} ${endpoint.name}</div>
                <div class="test-response">Testing...</div>
            </div>
            <div class="test-status testing">TESTING</div>
        `;
        container.appendChild(resultDiv);

        try {
            const options = {
                method: endpoint.method,
                headers: {
                    'Content-Type': 'application/json'
                }
            };

            if (endpoint.body) {
                options.body = JSON.stringify(endpoint.body);
            }

            const response = await fetch(`${endpoint.url}?key=${this.apiKey}`, options);
            const responseText = await response.text();
            
            const statusElement = resultDiv.querySelector('.test-status');
            const responseElement = resultDiv.querySelector('.test-response');
            
            if (response.ok) {
                statusElement.textContent = 'SUCCESS';
                statusElement.className = 'test-status success';
                responseElement.textContent = `${response.status} - ${responseText.substring(0, 100)}${responseText.length > 100 ? '...' : ''}`;
            } else {
                statusElement.textContent = 'ERROR';
                statusElement.className = 'test-status error';
                responseElement.textContent = `${response.status} - ${responseText}`;
            }
        } catch (err) {
            const statusElement = resultDiv.querySelector('.test-status');
            const responseElement = resultDiv.querySelector('.test-response');
            
            statusElement.textContent = 'ERROR';
            statusElement.className = 'test-status error';
            responseElement.textContent = `Network Error: ${err.message}`;
        }
    }

    clearTestResults() {
        document.getElementById('api-test-results').innerHTML = '<p style="color: #888; text-align: center; padding: 20px;">Click "Test All APIs" to run tests</p>';
    }

    // System Status
    updateSystemStatus() {
        // Update WebSocket status based on connection
        const wsStatus = document.getElementById('websocket-status');
        if (this.socket && this.socket.connected) {
            wsStatus.textContent = 'Connected';
            wsStatus.className = 'status-badge connected';
        } else {
            wsStatus.textContent = 'Disconnected';
            wsStatus.className = 'status-badge disconnected';
        }

        // Test MongoDB connection
        this.testMongoConnection();
        
        // Test Haraka integration
        this.testHarakaIntegration();
    }

    async testMongoConnection() {
        try {
            const response = await fetch(`/admin/test-mongo?key=${this.apiKey}`);
            const mongoStatus = document.getElementById('mongodb-status');
            
            if (response.ok) {
                mongoStatus.textContent = 'Connected';
                mongoStatus.className = 'status-badge connected';
            } else {
                mongoStatus.textContent = 'Error';
                mongoStatus.className = 'status-badge error';
            }
        } catch (err) {
            const mongoStatus = document.getElementById('mongodb-status');
            mongoStatus.textContent = 'Disconnected';
            mongoStatus.className = 'status-badge disconnected';
        }
    }

    async testHarakaIntegration() {
        try {
            const response = await fetch(`/admin/test-haraka?key=${this.apiKey}`);
            const harakaStatus = document.getElementById('haraka-status');
            
            if (response.ok) {
                harakaStatus.textContent = 'Active';
                harakaStatus.className = 'status-badge active';
            } else {
                harakaStatus.textContent = 'Error';
                harakaStatus.className = 'status-badge error';
            }
        } catch (err) {
            const harakaStatus = document.getElementById('haraka-status');
            harakaStatus.textContent = 'Inactive';
            harakaStatus.className = 'status-badge inactive';
        }
    }

    // Page Data Loading
    loadPageData(page) {
        switch (page) {
            case 'dashboard':
                this.loadDashboardStats();
                break;
            case 'domains':
                this.loadDomains();
                break;
            case 'emails':
                this.loadRecentEmails();
                break;
            case 'settings':
                this.loadCurrentApiKey();
                this.updateSystemStatus();
                break;
        }
    }

    // Utility Functions
    isValidDomain(domain) {
        const domainRegex = /^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9]?\.[a-zA-Z]{2,}$/;
        return domainRegex.test(domain);
    }

    showMessage(text, type = 'info') {
        // Remove existing messages
        const existingMessages = document.querySelectorAll('.message');
        existingMessages.forEach(msg => msg.remove());

        const message = document.createElement('div');
        message.className = `message ${type}`;
        message.textContent = text;
        
        const addDomainForm = document.querySelector('.add-domain-form');
        addDomainForm.parentNode.insertBefore(message, addDomainForm.nextSibling);
        
        setTimeout(() => {
            message.remove();
        }, 5000);
    }
}

// Initialize admin panel when DOM is loaded
let adminPanel;
document.addEventListener('DOMContentLoaded', () => {
    adminPanel = new AdminPanel();
});

// Auto-refresh stats every 30 seconds
setInterval(() => {
    if (adminPanel) {
        adminPanel.loadDashboardStats();
    }
}, 30000);