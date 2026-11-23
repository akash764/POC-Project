import { LightningElement, api } from 'lwc';

export default class UnApartmentList extends LightningElement {
    @api apartments = [];
    @api selectedApartmentId = '';

    get apartmentItems() {
        if (!this.apartments) return [];
        return this.apartments.map(apt => ({
            ...apt,
            isSelected: apt.id === this.selectedApartmentId
        }));
    }

    handleApartmentSelect(event) {
        this.selectedApartmentId = event.detail.apartmentId;
        this.dispatchEvent(new CustomEvent('apartmentchange', {
            detail: {
                apartmentId: this.selectedApartmentId
            },
            bubbles: true,
            composed: true
        }));
    }
}