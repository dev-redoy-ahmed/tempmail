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
        this.initEmailMonitor();
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

    // Initialize email monitor
    initEmailMonitor() {
        // Initialize refresh emails button
        const refreshEmailsBtn = document.getElementById('refresh-emails');
        if (refreshEmailsBtn) {
            refreshEmailsBtn.addEventListener('click', () => this.loadRecentEmails());
        }
        
        // Make viewRawEmail globally accessible
        window.viewRawEmail = (emailId) => this.viewRawEmail(emailId);
        window.closeRawEmailModal = () => this.closeRawEmailModal();
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
                    <div class="email-item" data-email-id="${mail._id}">
                        <button class="view-raw-btn" onclick="viewRawEmail('${mail._id}')">
                            <i class="fas fa-code"></i> Raw
                        </button>
                        <div class="email-header">
                            <span class="email-from">${mail.from || 'Unknown'}</span>
                            <span class="email-date">${new Date(mail.timestamp || mail.createdAt).toLocaleString()}</span>
                        </div>
                        <div class="email-subject">${mail.subject || '(no subject)'}</div>
                        <div class="email-to">To: ${Array.isArray(mail.to) ? mail.to.join(', ') : mail.to}</div>
                        <div class="email-device">Device: ${mail.deviceId}</div>
                    </div>
                `).join('');
            }
        } catch (err) {
            console.error('Error loading recent emails:', err);
        }
    }

    async viewRawEmail(emailId) {
        try {
            const response = await fetch(`/admin/email/${emailId}/raw?key=${this.apiKey}`);
            if (response.ok) {
                const emailData = await response.json();
                
                // Populate modal with email data
                document.getElementById('raw-email-from').textContent = emailData.from || 'Unknown';
                document.getElementById('raw-email-to').textContent = Array.isArray(emailData.to) ? emailData.to.join(', ') : emailData.to;
                document.getElementById('raw-email-subject').textContent = emailData.subject || '(no subject)';
                document.getElementById('raw-email-timestamp').textContent = new Date(emailData.timestamp).toLocaleString();
                document.getElementById('raw-email-device').textContent = emailData.deviceId;
                document.getElementById('raw-email-content').textContent = emailData.raw || 'No raw data available';
                
                // Show modal
                document.getElementById('raw-email-modal').style.display = 'block';
            } else {
                this.showMessage('Failed to load raw email data', 'error');
            }
        } catch (err) {
            console.error('Error loading raw email:', err);
            this.showMessage('Error loading raw email data', 'error');
        }
    }

    closeRawEmailModal() {
        document.getElementById('raw-email-modal').style.display = 'none';
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
            case 'logs':
                this.initEmailLogs();
                this.loadEmailLogsData();
                break;
            case 'settings':
                this.loadCurrentApiKey();
                this.updateSystemStatus();
                break;
        }
    }

    // Email Logs Functionality
    initEmailLogs() {
        // Initialize refresh button
        const refreshBtn = document.getElementById('refresh-logs');
        if (refreshBtn) {
            refreshBtn.addEventListener('click', () => this.loadEmailLogsData());
        }

        // Initialize export button
        const exportBtn = document.getElementById('export-logs');
        if (exportBtn) {
            exportBtn.addEventListener('click', () => this.exportLogs());
        }

        // Initialize failed emails controls
        const retryBtn = document.getElementById('retry-failed-emails');
        if (retryBtn) {
            retryBtn.addEventListener('click', () => this.retryFailedEmails());
        }

        const clearBtn = document.getElementById('clear-failed-emails');
        if (clearBtn) {
            clearBtn.addEventListener('click', () => this.clearFailedEmails());
        }

        const viewBtn = document.getElementById('view-failed-details');
        if (viewBtn) {
            viewBtn.addEventListener('click', () => this.viewFailedEmailDetails());
        }

        // Initialize device search
        const deviceSearch = document.getElementById('device-search');
        if (deviceSearch) {
            deviceSearch.addEventListener('input', (e) => this.filterDevices(e.target.value));
        }

        // Initialize device sort
        const deviceSort = document.getElementById('device-sort');
        if (deviceSort) {
            deviceSort.addEventListener('change', (e) => this.sortDevices(e.target.value));
        }

        // Initialize activity filter
        const activityFilter = document.getElementById('activity-filter');
        if (activityFilter) {
            activityFilter.addEventListener('change', (e) => this.filterActivity(e.target.value));
        }

        // Initialize activity limit
        const activityLimit = document.getElementById('activity-limit');
        if (activityLimit) {
            activityLimit.addEventListener('change', (e) => this.updateActivityLimit(e.target.value));
        }
    }

    async loadEmailLogsData() {
        try {
            await Promise.all([
                this.loadSystemHealth(),
                this.loadEmailStatistics(),
                this.loadDeviceAnalytics(),
                this.loadFailedEmails(),
                this.loadRecentActivity()
            ]);
        } catch (error) {
            console.error('Error loading email logs data:', error);
        }
    }

    async loadSystemHealth() {
        try {
            const response = await fetch('/admin/health', {
                headers: { 'X-API-Key': this.apiKey }
            });
            const health = await response.json();

            // Update database status
            const dbStatus = document.getElementById('db-status');
            const dbDetails = document.getElementById('db-details');
            if (dbStatus && dbDetails) {
                dbStatus.textContent = health.database === 'connected' ? 'Connected' : 'Disconnected';
                dbDetails.textContent = health.database === 'connected' 
                    ? `${health.totalEmails} emails, ${health.totalDeviceEmails} device emails`
                    : health.databaseError || 'Connection failed';
                
                const healthCard = dbStatus.closest('.health-card');
                const icon = healthCard.querySelector('.health-icon');
                icon.className = `health-icon ${health.database === 'connected' ? 'success' : 'error'}`;
            }

            // Update failed emails count
            const failedCount = document.getElementById('failed-emails-count');
            const failedDetails = document.getElementById('failed-emails-details');
            if (failedCount && failedDetails) {
                failedCount.textContent = `${health.failedEmailsCount || 0} Failed`;
                failedDetails.textContent = health.failedEmailsLog 
                    ? `Log size: ${(health.failedEmailsLogSize / 1024).toFixed(2)} KB`
                    : 'No failed emails log';
            }

            // Update connected clients
            const clientsCount = document.getElementById('connected-clients');
            const clientDetails = document.getElementById('client-details');
            if (clientsCount && clientDetails) {
                clientsCount.textContent = `${health.connectedClients} Connected`;
                clientDetails.textContent = `Real-time connections`;
            }

        } catch (error) {
            console.error('Error loading system health:', error);
        }
    }

    async loadEmailStatistics() {
        try {
            const response = await fetch('/admin/stats', {
                headers: { 'X-API-Key': this.apiKey }
            });
            const stats = await response.json();

            // Update email counts
            document.getElementById('total-emails-count').textContent = stats.emails.total || 0;
            document.getElementById('today-emails-count').textContent = stats.emails.today || 0;
            document.getElementById('generated-emails-count').textContent = stats.deviceEmails.generated || 0;
            document.getElementById('received-emails-count').textContent = stats.deviceEmails.received || 0;
            document.getElementById('unique-devices-count').textContent = stats.deviceEmails.uniqueDevices || 0;
            document.getElementById('domains-count').textContent = stats.domains || 0;

        } catch (error) {
            console.error('Error loading email statistics:', error);
        }
    }

    async loadDeviceAnalytics() {
        try {
            // Get device analytics from device emails endpoint
            const response = await fetch('/api/device-emails/analytics', {
                headers: { 'X-API-Key': this.apiKey }
            });
            
            if (!response.ok) {
                // Fallback: aggregate from existing endpoints
                await this.loadDeviceAnalyticsFallback();
                return;
            }
            
            const devices = await response.json();
            this.renderDeviceList(devices);

        } catch (error) {
            console.error('Error loading device analytics:', error);
            await this.loadDeviceAnalyticsFallback();
        }
    }

    async loadDeviceAnalyticsFallback() {
        // This is a fallback method to aggregate device data from existing endpoints
        const deviceList = document.getElementById('device-list');
        deviceList.innerHTML = '<p style="color: #ccc; text-align: center; padding: 20px;">Device analytics endpoint not available. Please implement /api/device-emails/analytics endpoint.</p>';
    }

    renderDeviceList(devices) {
        const deviceList = document.getElementById('device-list');
        
        if (!devices || devices.length === 0) {
            deviceList.innerHTML = '<p style="color: #ccc; text-align: center; padding: 20px;">No devices found</p>';
            return;
        }

        deviceList.innerHTML = devices.map(device => `
            <div class="device-item">
                <div class="device-info">
                    <div class="device-id">${device.deviceId}</div>
                    <div class="device-stats">
                        <span>Generated: ${device.generatedCount || 0}</span>
                        <span>Received: ${device.receivedCount || 0}</span>
                        <span>Last Activity: ${device.lastActivity ? new Date(device.lastActivity).toLocaleDateString() : 'N/A'}</span>
                    </div>
                </div>
                <div class="device-actions">
                    <button class="btn btn-info" onclick="adminPanel.viewDeviceDetails('${device.deviceId}')">
                        <i class="fas fa-eye"></i> View
                    </button>
                    <button class="btn btn-danger" onclick="adminPanel.clearDeviceEmails('${device.deviceId}')">
                        <i class="fas fa-trash"></i> Clear
                    </button>
                </div>
            </div>
        `).join('');
    }

    async loadFailedEmails() {
        try {
            const response = await fetch('/admin/failed-emails', {
                headers: { 'X-API-Key': this.apiKey }
            });
            const data = await response.json();
            
            this.renderFailedEmailsList(data.emails || []);

        } catch (error) {
            console.error('Error loading failed emails:', error);
        }
    }

    renderFailedEmailsList(failedEmails) {
        const failedList = document.getElementById('failed-emails-list');
        
        if (!failedEmails || failedEmails.length === 0) {
            failedList.innerHTML = '<p style="color: #00ff88; text-align: center; padding: 20px;">✅ No failed emails</p>';
            return;
        }

        failedList.innerHTML = failedEmails.map((email, index) => `
            <div class="failed-email-item">
                <div class="failed-email-header">
                    Failed Email #${index + 1} - ${email.timestamp || 'Unknown time'}
                </div>
                <div class="failed-email-details">
                    To: ${email.to || 'Unknown'}
                    Subject: ${email.subject || 'No subject'}
                    Error: ${email.error || 'Unknown error'}
                </div>
            </div>
        `).join('');
    }

    async loadRecentActivity() {
        try {
            const limit = document.getElementById('activity-limit')?.value || 50;
            const filter = document.getElementById('activity-filter')?.value || 'all';
            
            const response = await fetch(`/admin/activity?limit=${limit}&filter=${filter}`, {
                headers: { 'X-API-Key': this.apiKey }
            });
            const activities = await response.json();
            
            this.renderActivityLog(activities);

        } catch (error) {
            console.error('Error loading recent activity:', error);
            const activityLog = document.getElementById('activity-log');
            activityLog.innerHTML = '<p style="color: #ff4444; text-align: center; padding: 20px;">Error loading activity logs</p>';
        }
    }

    renderActivityLog(activities) {
        const activityLog = document.getElementById('activity-log');
        
        if (!activities || activities.length === 0) {
            activityLog.innerHTML = '<p style="color: #ccc; text-align: center; padding: 20px;">No recent activity</p>';
            return;
        }

        activityLog.innerHTML = activities.map(activity => `
            <div class="activity-item ${activity.type}">
                <div class="activity-content">
                    <div class="activity-type ${activity.type}">${activity.type}</div>
                    <div class="activity-description">${activity.description}</div>
                </div>
                <div class="activity-timestamp">${new Date(activity.timestamp).toLocaleString()}</div>
            </div>
        `).join('');
    }

    async retryFailedEmails() {
        try {
            const response = await fetch('/admin/retry-failed-emails', {
                method: 'POST',
                headers: { 'X-API-Key': this.apiKey }
            });
            const result = await response.json();
            
            if (result.success) {
                this.showMessage('Failed emails retry initiated successfully', 'success');
                await this.loadFailedEmails();
                await this.loadSystemHealth();
            } else {
                this.showMessage('Failed to retry emails: ' + result.message, 'error');
            }

        } catch (error) {
            console.error('Error retrying failed emails:', error);
            this.showMessage('Error retrying failed emails', 'error');
        }
    }

    async clearFailedEmails() {
        if (!confirm('Are you sure you want to clear all failed email logs? This action cannot be undone.')) {
            return;
        }

        try {
            const response = await fetch('/admin/failed-emails', {
                method: 'DELETE',
                headers: { 'X-API-Key': this.apiKey }
            });
            const result = await response.json();
            
            if (result.success) {
                this.showMessage('Failed emails log cleared successfully', 'success');
                await this.loadFailedEmails();
                await this.loadSystemHealth();
            } else {
                this.showMessage('Failed to clear emails log', 'error');
            }

        } catch (error) {
            console.error('Error clearing failed emails:', error);
            this.showMessage('Error clearing failed emails log', 'error');
        }
    }

    viewFailedEmailDetails() {
        const failedList = document.getElementById('failed-emails-list');
        const items = failedList.querySelectorAll('.failed-email-item');
        
        items.forEach(item => {
            const details = item.querySelector('.failed-email-details');
            if (details.style.maxHeight === 'none') {
                details.style.maxHeight = '100px';
            } else {
                details.style.maxHeight = 'none';
            }
        });
    }

    filterDevices(searchTerm) {
        const deviceItems = document.querySelectorAll('.device-item');
        
        deviceItems.forEach(item => {
            const deviceId = item.querySelector('.device-id').textContent.toLowerCase();
            if (deviceId.includes(searchTerm.toLowerCase())) {
                item.style.display = 'flex';
            } else {
                item.style.display = 'none';
            }
        });
    }

    sortDevices(sortBy) {
        // This would require re-fetching and sorting the device data
        console.log('Sorting devices by:', sortBy);
        // Implementation would depend on the backend providing sorted data
    }

    filterActivity(filterType) {
        // Reload activity with new filter
        this.loadRecentActivity();
    }

    updateActivityLimit(limit) {
        // Reload activity with new limit
        this.loadRecentActivity();
    }

    async viewDeviceDetails(deviceId) {
        try {
            const response = await fetch(`/api/device/${deviceId}/emails`, {
                headers: { 'X-API-Key': this.apiKey }
            });
            const emails = await response.json();
            
            // Show device details in a modal or expand the device item
            alert(`Device ${deviceId} has ${emails.length} emails`);
            
        } catch (error) {
            console.error('Error viewing device details:', error);
        }
    }

    async clearDeviceEmails(deviceId) {
        if (!confirm(`Are you sure you want to clear all emails for device ${deviceId}?`)) {
            return;
        }

        try {
            const response = await fetch(`/api/device/${deviceId}/clear`, {
                method: 'DELETE',
                headers: { 'X-API-Key': this.apiKey }
            });
            
            if (response.ok) {
                this.showMessage(`Emails cleared for device ${deviceId}`, 'success');
                await this.loadDeviceAnalytics();
                await this.loadEmailStatistics();
            } else {
                this.showMessage('Failed to clear device emails', 'error');
            }

        } catch (error) {
            console.error('Error clearing device emails:', error);
            this.showMessage('Error clearing device emails', 'error');
        }
    }

    exportLogs() {
        // Export functionality
        const data = {
            timestamp: new Date().toISOString(),
            health: 'Would include health data',
            statistics: 'Would include statistics',
            devices: 'Would include device analytics',
            failedEmails: 'Would include failed emails'
        };
        
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `email-logs-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
        
        this.showMessage('Logs exported successfully', 'success');
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