import { LightningElement, api } from 'lwc';

export default class UnErrorMessage extends LightningElement {
    @api title = 'Something Went Wrong';
    @api message = 'We encountered an unexpected error while retrieving data. Please check your connection and try again.';
    @api allowRetry = false;

    handleRetry() {
        this.dispatchEvent(new CustomEvent('retry', {
            bubbles: true,
            composed: true
        }));
    }
}