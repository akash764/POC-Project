import { LightningElement, api } from 'lwc';

export default class UnEmptyState extends LightningElement {
    @api icon = '🔍';
    @api title = 'No Properties Found';
    @api description = 'We could not find any projects matching your selected filter criteria. Try adjusting your city or state selection.';
    @api actionLabel = 'Reset All Filters';

    handleAction() {
        this.dispatchEvent(new CustomEvent('action', {
            bubbles: true,
            composed: true
        }));
    }
}