import { LightningElement, api, track, wire } from 'lwc';
import submitEnquiry from '@salesforce/apex/UNEnquiryController.submitEnquiry';
import getProjects from '@salesforce/apex/UNProjectController.getProjects';

export default class UnEnquiryForm extends LightningElement {
    _preselectedProjectId = '';
    _preselectedProjectName = '';
    _preselectedBhk = '';
    _preselectedBudget = '';
    _preselectedUnitNumber = '';

    @api
    get preselectedProjectId() {
        return this._preselectedProjectId;
    }
    set preselectedProjectId(val) {
        this._preselectedProjectId = val || '';
        this.rebuildProjectOptions();
    }

    @api
    get preselectedProjectName() {
        return this._preselectedProjectName;
    }
    set preselectedProjectName(val) {
        this._preselectedProjectName = val || '';
        this.rebuildProjectOptions();
    }

    @api
    get preselectedBhk() {
        return this._preselectedBhk;
    }
    set preselectedBhk(val) {
        this._preselectedBhk = val || '';
        if (this._preselectedBhk) {
            this.bhkPreference = this._preselectedBhk;
        }
    }

    @api
    get preselectedBudget() {
        return this._preselectedBudget;
    }
    set preselectedBudget(val) {
        this._preselectedBudget = val || '';
        if (this._preselectedBudget) {
            this.budget = String(this._preselectedBudget);
        }
    }

    @api
    get preselectedUnitNumber() {
        return this._preselectedUnitNumber;
    }
    set preselectedUnitNumber(val) {
        this._preselectedUnitNumber = val || '';
    }

    @api isModal = false;
    @api formTitle = 'Request Project Information';
    @api formSubtitle = 'Share your requirements and our certified property consultants will reach out with detailed brochures and floor layouts.';

    @track fullName = '';
    @track phone = '';
    @track email = '';
    @track locationPreference = '';
    @track selectedProjectId = '';
    @track bhkPreference = '';
    @track budget = '';
    @track whatsAppOptIn = true;

    @track errors = {};
    @track isSubmitting = false;
    @track isSubmitted = false;
    @track successMessage = '';
    @track serverErrorMessage = '';
    @track projectOptions = [];

    serverProjects = [];
    submissionKey = '';
    campaignId = '';

    connectedCallback() {
        this.generateSubmissionKey();
        this.extractUrlParameters();
        this.initPreselectedFields();
    }

    renderedCallback() {
        const projSelect = this.template.querySelector('#enquiry-project');
        if (projSelect && this.selectedProjectId && projSelect.value !== this.selectedProjectId) {
            projSelect.value = this.selectedProjectId;
        }
        const bhkSelect = this.template.querySelector('#enquiry-bhk');
        if (bhkSelect && this.bhkPreference && bhkSelect.value !== this.bhkPreference) {
            bhkSelect.value = this.bhkPreference;
        }
    }

    extractUrlParameters() {
        try {
            if (typeof window !== 'undefined' && window.location && window.location.search) {
                const params = new URLSearchParams(window.location.search);
                if (params.has('campaignId')) {
                    this.campaignId = params.get('campaignId');
                }
            }
        } catch (e) {
            // Safe fallback
        }
    }

    initPreselectedFields() {
        if (this.preselectedBhk) {
            this.bhkPreference = this.preselectedBhk;
        }
        if (this.preselectedBudget) {
            this.budget = String(this.preselectedBudget);
        }
        this.rebuildProjectOptions();
    }

    @wire(getProjects, { city: '', state: '', limitCount: 50, offsetCount: 0 })
    wiredProjects({ data, error }) {
        if (data) {
            this.serverProjects = data.map(p => ({
                label: p.city ? `${p.name} (${p.city})` : p.name,
                value: p.id,
                name: p.name,
                city: p.city
            }));
            this.rebuildProjectOptions();
        }
    }

    rebuildProjectOptions() {
        let opts = [...this.serverProjects];
        const targetId = this._preselectedProjectId;
        const targetName = this._preselectedProjectName;

        let matched = false;
        let matchedCity = '';

        // Try to match by Id
        if (targetId) {
            const foundById = opts.find(o => o.value === targetId);
            if (foundById) {
                this.selectedProjectId = foundById.value;
                matchedCity = foundById.city;
                matched = true;
            }
        }

        // Try to match by Project Name (exact or case-insensitive substring)
        if (!matched && targetName) {
            const targetLower = targetName.toLowerCase();
            const foundByName = opts.find(o => {
                if (!o.name) return false;
                const oLower = o.name.toLowerCase();
                return oLower === targetLower || targetLower.includes(oLower) || oLower.includes(targetLower);
            });
            if (foundByName) {
                this.selectedProjectId = foundByName.value;
                matchedCity = foundByName.city;
                matched = true;
            }
        }

        // If targetName or targetId exists but not in server list (e.g. sample data or consultation)
        if (!matched && (targetName || targetId)) {
            const isGeneral = targetName === 'General UrbanNest Consultation' || targetName === 'General Project Consultation';
            if (!isGeneral) {
                const label = targetName || 'Selected Project';
                const value = targetId || targetName;
                opts = [{ label: label, value: value, name: targetName }, ...opts];
                this.selectedProjectId = value;
            }
        }

        this.projectOptions = opts.map(o => ({
            ...o,
            isSelected: String(o.value) === String(this.selectedProjectId)
        }));

        // Auto-fill location preference from matched project city if locationPreference is empty
        if (matchedCity && !this.locationPreference) {
            this.locationPreference = matchedCity;
        }

        // Sync BHK and Budget if not already set
        if (this._preselectedBhk && !this.bhkPreference) {
            this.bhkPreference = this._preselectedBhk;
        }
        if (this._preselectedBudget && !this.budget) {
            this.budget = String(this._preselectedBudget);
        }
    }

    get bhkOptions() {
        const standard = [
            { label: 'Select Configuration', value: '' },
            { label: '1 BHK', value: '1 BHK' },
            { label: '2 BHK', value: '2 BHK' },
            { label: '3 BHK', value: '3 BHK' },
            { label: '4 BHK', value: '4 BHK' },
            { label: '5+ BHK / Penthouse', value: '5+ BHK' },
            { label: 'Luxury Villa', value: 'Villa' },
            { label: 'Commercial Space / Office', value: 'Commercial Space' }
        ];

        const current = this.bhkPreference || this._preselectedBhk;
        let list = standard;
        if (current && !standard.some(o => o.value === current)) {
            list = [
                ...standard,
                { label: current, value: current }
            ];
        }
        return list.map(o => ({
            ...o,
            isSelected: o.value === current
        }));
    }

    get computedFormTitle() {
        if (this._preselectedUnitNumber && this._preselectedProjectName) {
            return `Enquire for ${this._preselectedUnitNumber} — ${this._preselectedProjectName}`;
        }
        if (this._preselectedUnitNumber) {
            return `Enquire for ${this._preselectedUnitNumber}`;
        }
        if (this._preselectedProjectName && !this._preselectedProjectName.startsWith('General')) {
            return `Enquire about ${this._preselectedProjectName}`;
        }
        return this.formTitle || 'Request Project Information';
    }

    get computedFormSubtitle() {
        if (this._preselectedUnitNumber && (this._preselectedBhk || this.bhkPreference)) {
            const bhk = this._preselectedBhk || this.bhkPreference;
            const priceVal = this.budget || this._preselectedBudget;
            let priceText = '';
            if (priceVal) {
                const p = Number(priceVal);
                if (p >= 10000000) {
                    priceText = ` • ₹ ${(p / 10000000).toFixed(2)} Cr*`;
                } else if (p >= 100000) {
                    priceText = ` • ₹ ${(p / 100000).toFixed(2)} Lacs*`;
                } else {
                    priceText = ` • ₹ ${p.toLocaleString('en-IN')}`;
                }
            }
            return `Selected Unit: ${this._preselectedUnitNumber} (${bhk}${priceText}). Our certified property consultants will reach out with floor layouts and pricing.`;
        }
        return this.formSubtitle || 'Share your requirements and our certified property consultants will reach out with detailed brochures and floor layouts.';
    }

    get isProjectLocked() {
        return false;
    }

    get containerClass() {
        return this.isModal ? 'un-enquiry-card is-modal' : 'un-enquiry-card';
    }

    get nameInputClass() {
        return this.errors.fullName ? 'un-input is-invalid' : 'un-input';
    }

    get phoneInputClass() {
        return this.errors.phone ? 'un-input is-invalid' : 'un-input';
    }

    get emailInputClass() {
        return this.errors.email ? 'un-input is-invalid' : 'un-input';
    }

    get locationInputClass() {
        return this.errors.locationPreference ? 'un-input is-invalid' : 'un-input';
    }

    get budgetInputClass() {
        return this.errors.budget ? 'un-input is-invalid' : 'un-input';
    }

    generateSubmissionKey() {
        this.submissionKey = 'UN-' + Date.now() + '-' + Math.random().toString(36).substring(2, 10);
    }

    handleNameChange(e) {
        this.fullName = e.target.value;
        this.clearFieldError('fullName');
    }

    handlePhoneChange(e) {
        this.phone = e.target.value;
        this.clearFieldError('phone');
    }

    handleEmailChange(e) {
        this.email = e.target.value;
        this.clearFieldError('email');
    }

    handleLocationChange(e) {
        this.locationPreference = e.target.value;
        this.clearFieldError('locationPreference');
    }

    handleProjectChange(e) {
        this.selectedProjectId = e.target.value;
        const matched = this.serverProjects.find(p => p.value === this.selectedProjectId);
        if (matched && matched.city && !this.locationPreference) {
            this.locationPreference = matched.city;
            this.clearFieldError('locationPreference');
        }
    }

    handleBhkChange(e) {
        this.bhkPreference = e.target.value;
    }

    handleBudgetChange(e) {
        this.budget = e.target.value;
        this.clearFieldError('budget');
    }

    handleWhatsAppChange(e) {
        this.whatsAppOptIn = e.target.checked;
    }

    clearFieldError(field) {
        if (this.errors[field]) {
            this.errors = { ...this.errors, [field]: null };
        }
    }

    validateInputs() {
        const errs = {};
        if (!this.fullName || !this.fullName.trim()) {
            errs.fullName = 'Please enter your full name.';
        }

        if (!this.locationPreference || !this.locationPreference.trim()) {
            errs.locationPreference = 'Please indicate your preferred location (e.g. Anna Nagar, OMR).';
        }

        const trimmedPhone = this.phone ? this.phone.trim() : '';
        const trimmedEmail = this.email ? this.email.trim() : '';

        if (!trimmedPhone && !trimmedEmail) {
            errs.phone = 'Please provide either a phone number or email address.';
            errs.email = 'Please provide either an email address or phone number.';
        } else {
            if (trimmedPhone) {
                const digits = trimmedPhone.replace(/\D/g, '');
                if (digits.length < 10) {
                    errs.phone = 'Please enter a valid 10-digit phone number.';
                }
            }
            if (trimmedEmail) {
                const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
                if (!emailRegex.test(trimmedEmail)) {
                    errs.email = 'Please enter a valid email address.';
                }
            }
        }

        if (this.budget) {
            const numBudget = Number(this.budget);
            if (isNaN(numBudget) || numBudget < 0) {
                errs.budget = 'Budget cannot be negative.';
            }
        }

        this.errors = errs;
        return Object.keys(errs).length === 0;
    }

    async handleSubmit(event) {
        event.preventDefault();
        this.serverErrorMessage = '';

        if (!this.validateInputs()) {
            return;
        }

        this.isSubmitting = true;

        const isValidSfId = (id) => typeof id === 'string' && (id.length === 15 || id.length === 18) && !id.startsWith('sample') && !id.startsWith('custom');

        const payload = {
            submissionKey: this.submissionKey,
            fullName: this.fullName.trim(),
            phone: this.phone ? this.phone.trim() : null,
            email: this.email ? this.email.trim() : null,
            locationPreference: this.locationPreference ? this.locationPreference.trim() : null,
            projectId: isValidSfId(this.selectedProjectId) ? this.selectedProjectId : null,
            campaignId: isValidSfId(this.campaignId) ? this.campaignId : null,
            bhkPreference: this.bhkPreference || null,
            budget: this.budget ? Number(this.budget) : null,
            whatsAppOptIn: this.whatsAppOptIn
        };

        try {
            const result = await submitEnquiry({ enquiry: payload });

            if (result && result.isSuccess) {
                this.isSubmitted = true;
                this.successMessage = (result.message || 'Thank you for your enquiry. We will contact you shortly.') +
                    ' Redirecting you to our home page...';
                this.dispatchEvent(new CustomEvent('success', {
                    bubbles: true,
                    composed: true
                }));
                setTimeout(() => {
                    if (typeof window !== 'undefined' && window.location) {
                        const isUrbanNestPath = window.location.pathname.toLowerCase().includes('/urbannest');
                        window.location.href = isUrbanNestPath ? '/UrbanNest' : '/';
                    }
                }, 2200);
            } else {
                this.serverErrorMessage = (result && result.message) ? result.message : 'Unable to submit enquiry. Please try again.';
            }
        } catch (err) {
            this.serverErrorMessage = (err && err.body && err.body.message)
                ? err.body.message
                : 'Connection error. Please try again later.';
        } finally {
            this.isSubmitting = false;
        }
    }

    handleResetForm() {
        this.isSubmitted = false;
        this.fullName = '';
        this.phone = '';
        this.email = '';
        this.locationPreference = '';
        this.serverErrorMessage = '';
        this.errors = {};
        this.generateSubmissionKey();
        this.initPreselectedFields();
    }
}