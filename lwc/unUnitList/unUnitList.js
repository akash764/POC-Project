import { LightningElement, api, track } from 'lwc';

const ALLOWED_STATUSES = new Set(['available', 'under offer']);

export default class UnUnitList extends LightningElement {
    @api units = [];
    @track activeBhk = 'ALL';

    get visibleUnits() {
        if (!this.units || !Array.isArray(this.units)) return [];
        return this.units.filter(u => {
            const status = (u.status || '').trim().toLowerCase();
            return ALLOWED_STATUSES.has(status);
        });
    }

    get bhkTabs() {
        const list = this.visibleUnits;
        if (!list || list.length === 0) return [];
        const counts = { 'ALL': list.length, '1 BHK': 0, '2 BHK': 0, '3 BHK': 0, '4 BHK': 0, '5 BHK': 0 };

        list.forEach(u => {
            if (u.bhk && counts[u.bhk] !== undefined) {
                counts[u.bhk]++;
            }
        });

        const tabs = [
            { label: 'All Units', value: 'ALL', count: counts['ALL'] },
            { label: '1 BHK', value: '1 BHK', count: counts['1 BHK'] },
            { label: '2 BHK', value: '2 BHK', count: counts['2 BHK'] },
            { label: '3 BHK', value: '3 BHK', count: counts['3 BHK'] }
        ];

        if (counts['4 BHK'] > 0) {
            tabs.push({ label: '4 BHK', value: '4 BHK', count: counts['4 BHK'] });
        }
        if (counts['5 BHK'] > 0) {
            tabs.push({ label: '5 BHK', value: '5 BHK', count: counts['5 BHK'] });
        }

        return tabs.map(t => ({
            ...t,
            cssClass: this.activeBhk === t.value ? 'un-bhk-tab is-active' : 'un-bhk-tab'
        }));
    }

    get filteredUnits() {
        const list = this.visibleUnits;
        if (!list || list.length === 0) return [];
        if (this.activeBhk === 'ALL') {
            return list;
        }
        return list.filter(u => u.bhk === this.activeBhk);
    }

    get hasFilteredUnits() {
        return this.filteredUnits && this.filteredUnits.length > 0;
    }

    handleTabSelect(event) {
        this.activeBhk = event.currentTarget.dataset.bhk;
    }

    handleUnitEnquire(event) {
        this.dispatchEvent(new CustomEvent('unitenquire', {
            detail: event.detail,
            bubbles: true,
            composed: true
        }));
    }
}