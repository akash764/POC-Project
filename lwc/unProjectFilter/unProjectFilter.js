import { LightningElement, api } from 'lwc';

export default class UnProjectFilter extends LightningElement {
    @api cities = [];
    @api states = [];
    @api stateCityMap = {};
    @api selectedCity = '';
    @api selectedState = '';

    get isClearDisabled() {
        return !this.selectedCity && !this.selectedState;
    }

    get filteredCities() {
        if (this.selectedState && this.stateCityMap && this.stateCityMap[this.selectedState]) {
            return this.stateCityMap[this.selectedState];
        }
        return this.cities || [];
    }

    handleCityChange(event) {
        this.selectedCity = event.target.value;
        this.notifyFilterChange();
    }

    handleStateChange(event) {
        this.selectedState = event.target.value;
        const validCities = this.filteredCities;
        if (this.selectedCity && !validCities.includes(this.selectedCity)) {
            this.selectedCity = '';
            const citySelect = this.template.querySelector('#filter-city');
            if (citySelect) citySelect.value = '';
        }
        this.notifyFilterChange();
    }

    handleClear() {
        this.selectedCity = '';
        this.selectedState = '';
        const citySelect = this.template.querySelector('#filter-city');
        const stateSelect = this.template.querySelector('#filter-state');
        if (citySelect) citySelect.value = '';
        if (stateSelect) stateSelect.value = '';
        this.notifyFilterChange();
    }

    notifyFilterChange() {
        this.dispatchEvent(new CustomEvent('filterchange', {
            detail: {
                city: this.selectedCity,
                state: this.selectedState
            },
            bubbles: true,
            composed: true
        }));
    }
}