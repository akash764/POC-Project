import { LightningElement, api } from 'lwc';

export default class UnProjectList extends LightningElement {
    @api projects = [];
    @api isLoading = false;
    @api hasError = false;
    @api errorMessage = '';

    get hasProjects() {
        return this.projects && this.projects.length > 0;
    }

    handleProjectSelect(event) {
        this.dispatchEvent(new CustomEvent('selectproject', {
            detail: event.detail,
            bubbles: true,
            composed: true
        }));
    }

    handleProjectEnquire(event) {
        this.dispatchEvent(new CustomEvent('enquireproject', {
            detail: event.detail,
            bubbles: true,
            composed: true
        }));
    }

    handleRetry() {
        this.dispatchEvent(new CustomEvent('retry', {
            bubbles: true,
            composed: true
        }));
    }

    handleReset() {
        this.dispatchEvent(new CustomEvent('resetfilters', {
            bubbles: true,
            composed: true
        }));
    }
}