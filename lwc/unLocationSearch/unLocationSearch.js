import { LightningElement, api, wire, track } from 'lwc';
import getLocationFilterOptions from '@salesforce/apex/UNProjectController.getLocationFilterOptions';

export default class UnLocationSearch extends LightningElement {
    @api selectedCity = '';
    @api selectedState = '';

    @track allCities = [];
    @track states = [];
    @track stateCityMap = {};

    @wire(getLocationFilterOptions)
    wiredOptions({ data, error }) {
        if (data) {
            this.allCities = data.cities || [];
            this.states = data.states || [];
            this.stateCityMap = data.stateCityMap || {};
        } else if (error) {
            this.allCities = ['Chennai', 'Bengaluru', 'Coimbatore', 'Hyderabad'];
            this.states = ['Tamil Nadu', 'Karnataka', 'Telangana'];
            this.stateCityMap = {
                'Tamil Nadu': ['Chennai', 'Coimbatore'],
                'Karnataka': ['Bengaluru', 'Bangalore'],
                'Telangana': ['Hyderabad']
            };
        }
    }

    get filteredCities() {
        if (this.selectedState && this.stateCityMap && this.stateCityMap[this.selectedState]) {
            return this.stateCityMap[this.selectedState];
        }
        return this.allCities;
    }

    handleStateChange(event) {
        this.selectedState = event.target.value;

        // If the previously selected city is not in the newly selected state, reset it
        const validCities = this.filteredCities;
        if (this.selectedCity && !validCities.includes(this.selectedCity)) {
            this.selectedCity = '';
            const citySelect = this.template.querySelector('#city-select');
            if (citySelect) {
                citySelect.value = '';
            }
        }
    }

    handleCityChange(event) {
        this.selectedCity = event.target.value;
    }

    handleSearch() {
        this.dispatchEvent(new CustomEvent('search', {
            detail: {
                city: this.selectedCity,
                state: this.selectedState
            },
            bubbles: true,
            composed: true
        }));
    }

    handleReset() {
        this.selectedCity = '';
        this.selectedState = '';
        const citySelect = this.template.querySelector('#city-select');
        const stateSelect = this.template.querySelector('#state-select');
        if (citySelect) citySelect.value = '';
        if (stateSelect) stateSelect.value = '';
        this.dispatchEvent(new CustomEvent('search', {
            detail: {
                city: '',
                state: ''
            },
            bubbles: true,
            composed: true
        }));
    }
}