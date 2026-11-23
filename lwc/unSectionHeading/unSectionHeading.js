import { LightningElement, api } from 'lwc';

export default class UnSectionHeading extends LightningElement {
    @api eyebrow = '';
    @api title = '';
    @api subtitle = '';
    @api align = 'center'; // 'center' or 'left'

    get containerClass() {
        return this.align === 'left' ? 'un-section-header align-left' : 'un-section-header align-center';
    }
}