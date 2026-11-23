import { LightningElement, track } from 'lwc';

/**
 * @slot default The primary page content slot in Experience Cloud LWR.
 */
export default class UnSiteLayout extends LightningElement {
    @track isEnquiryModalOpen = false;
    @track enquiryProjectId = '';
    @track enquiryProjectName = '';
    @track enquiryBhk = '';
    @track enquiryBudget = '';
    @track enquiryUnitNumber = '';

    boundGlobalModalHandler = null;

    connectedCallback() {
        this.boundGlobalModalHandler = this.handleGlobalOpenModal.bind(this);
        window.addEventListener('openquickmodal', this.boundGlobalModalHandler);
    }

    disconnectedCallback() {
        if (this.boundGlobalModalHandler) {
            window.removeEventListener('openquickmodal', this.boundGlobalModalHandler);
        }
    }

    handleGlobalOpenModal(event) {
        if (event && event.detail) {
            this.populateEnquiryDetails(event.detail);
        }
        this.isEnquiryModalOpen = true;
    }

    handleOpenEnquiry(event) {
        if (event && event.detail) {
            this.populateEnquiryDetails(event.detail);
        }
        this.isEnquiryModalOpen = true;
    }

    populateEnquiryDetails(detail) {
        this.enquiryProjectId = detail.projectId || '';
        this.enquiryProjectName = detail.projectName || '';
        this.enquiryBhk = detail.bhk || detail.unitType || '';
        this.enquiryBudget = detail.budget ? String(detail.budget) : (detail.price ? String(detail.price) : '');
        this.enquiryUnitNumber = detail.unitNumber || '';
    }

    handleCloseEnquiry() {
        this.isEnquiryModalOpen = false;
        this.enquiryProjectId = '';
        this.enquiryProjectName = '';
        this.enquiryBhk = '';
        this.enquiryBudget = '';
        this.enquiryUnitNumber = '';
    }

    handleModalClick(event) {
        event.stopPropagation();
    }

    handleEnquirySuccess() {
        // Automatically close modal after brief delay on success
        setTimeout(() => {
            this.handleCloseEnquiry();
        }, 3000);
    }
}