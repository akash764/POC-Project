import { LightningElement, api } from 'lwc';

export default class UnUnitCard extends LightningElement {
    @api unit = {};

    get statusBadgeClass() {
        if (!this.unit || !this.unit.status) return 'un-status-badge';
        const s = this.unit.status.toLowerCase().replace(/\s+/g, '-');
        return `un-status-badge status-${s}`;
    }

    get isVilla() {
        return (this.unit?.recordTypeName === 'Villa_Unit') || Boolean(this.unit?.plotArea);
    }

    get isCommercial() {
        return (this.unit?.recordTypeName === 'Commercial_Space') || (!this.unit?.bhk && Boolean(this.unit?.furnishingStatus));
    }

    get isApartmentOrCommercial() {
        return !this.isVilla;
    }

    get displayBhk() {
        return this.unit?.bhk ? this.unit.bhk : '';
    }

    get displayType() {
        return this.unit?.unitType || 'Commercial Space';
    }

    get areaLabel() {
        if (this.isVilla) return 'Carpet Area';
        if (this.isCommercial) return 'Leasable Area';
        return 'Super Built-up';
    }

    get areaValue() {
        return this.unit?.carpetArea || this.unit?.superBuiltUpArea || this.unit?.area || '—';
    }

    get bathsLabel() {
        return this.isCommercial ? 'Restrooms' : 'Baths';
    }

    get formattedPrice() {
        if (this.unit && this.unit.price) {
            const p = this.unit.price;
            if (p >= 10000000) {
                return `₹ ${(p / 10000000).toFixed(2)} Cr*`;
            } else if (p >= 100000) {
                return `₹ ${(p / 100000).toFixed(2)} Lacs*`;
            }
            return `₹ ${p.toLocaleString('en-IN')}*`;
        }
        return 'Price On Request';
    }

    get floorLabel() {
        if (!this.unit || this.unit.floor === undefined || this.unit.floor === null) return 'N/A';
        return this.unit.floor === 0 ? 'Ground (0)' : `${this.unit.floor}${this.getOrdinal(this.unit.floor)} Flr`;
    }

    get parkingText() {
        if (!this.unit || !this.unit.parkingAvailable) return 'Optional';
        return this.isVilla ? 'Private Garage' : 'Dedicated';
    }

    get formattedPossessionDate() {
        if (!this.unit || !this.unit.possessionDate) return 'Ready / In Progress';
        try {
            const d = new Date(this.unit.possessionDate);
            return d.toLocaleDateString('en-IN', { month: 'short', year: 'numeric' });
        } catch (e) {
            return this.unit.possessionDate;
        }
    }

    getOrdinal(n) {
        const s = ['th', 'st', 'nd', 'rd'];
        const v = n % 100;
        return s[(v - 20) % 10] || s[v] || s[0];
    }

    handleUnitEnquire() {
        this.dispatchEvent(new CustomEvent('unitenquire', {
            detail: {
                unitId: this.unit?.id,
                unitNumber: this.unit?.unitNumber,
                bhk: this.unit?.bhk,
                unitType: this.unit?.unitType,
                price: this.unit?.price,
                recordTypeName: this.unit?.recordTypeName
            },
            bubbles: true,
            composed: true
        }));
    }
}