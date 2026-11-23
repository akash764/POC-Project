import { LightningElement, track } from 'lwc';
import URBANNEST_LOGO from '@salesforce/resourceUrl/UrbanNest_Logo';

export default class UnHeader extends LightningElement {
    @track isMobileMenuOpen = false;

    logoUrl = URBANNEST_LOGO;

    get hamburgerClass() {
        return this.isMobileMenuOpen ? 'un-hamburger-lines is-active' : 'un-hamburger-lines';
    }

    toggleMobileMenu() {
        this.isMobileMenuOpen = !this.isMobileMenuOpen;
    }

    closeMobileMenu() {
        this.isMobileMenuOpen = false;
    }

    handleDrawerClick(event) {
        event.stopPropagation();
    }

    handleQuickEnquiry() {
        // Dispatch to parent layout container
        this.dispatchEvent(new CustomEvent('openenquiry', {
            detail: {
                projectId: '',
                projectName: 'General UrbanNest Consultation'
            },
            bubbles: true,
            composed: true
        }));

        // Dispatch globally for Experience Cloud LWR theme layout listeners
        try {
            window.dispatchEvent(new CustomEvent('openquickmodal', {
                detail: {
                    projectId: '',
                    projectName: 'General UrbanNest Consultation'
                }
            }));
        } catch (e) {
            // Safe fallback
        }
    }

    handleQuickEnquiryMobile() {
        this.closeMobileMenu();
        this.handleQuickEnquiry();
    }
}