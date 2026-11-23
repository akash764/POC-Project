import { LightningElement, api } from 'lwc';

export default class UnApartmentCard extends LightningElement {
    @api apartment = {};
    @api isSelected = false;

    get cardClass() {
        return this.isSelected ? 'un-apt-card is-selected' : 'un-apt-card';
    }

    get statusBadgeClass() {
        const status = (this.apartment && this.apartment.constructionStatus)
            ? this.apartment.constructionStatus.toLowerCase().replace(/\s+/g, '-')
            : 'not-started';
        return `un-apt-badge un-apt-badge-${status}`;
    }

    get phaseIcon() {
        if (!this.apartment) return '🏢';
        const t = (this.apartment.phaseType || '').toLowerCase();
        if (t.includes('villa')) return '🏡';
        if (t.includes('commercial') || t.includes('retail') || t.includes('corporate') || t.includes('wing')) return '🏬';
        return '🏗️';
    }

    get floorLabelHeading() {
        const t = (this.apartment?.phaseType || '').toLowerCase();
        return t.includes('villa') ? 'Levels' : 'Total Floors';
    }

    get selectButtonText() {
        return this.isSelected ? 'Viewing Inventory' : 'Explore Inventory';
    }

    handleCardClick() {
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                apartmentId: this.apartment.id
            },
            bubbles: true,
            composed: true
        }));
    }
}