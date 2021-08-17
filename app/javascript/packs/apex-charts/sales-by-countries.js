import ApexCharts from 'apexcharts';
$(document).on('turbolinks:load', function () {
    var options = {
        chart: {
            width: '100%',
            height: 391,
            type: 'pie',
        },
        labels: ['UK', 'USA', 'Canada', 'Australia', 'Italy'],
        colors: ['#2962ff', '#2458e5', '#204ecc', '#1c44b2', '#183a99'],
        series: [500, 800, 500, 300, 250],
        responsive: [{
            breakpoint: 300,
            options: {
                chart: {
                    width: 200
                },
                legend: {
                    position: 'bottom'
                }
            }
        }],
        legend: {
            horizontalAlign: 'right',
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#sales-by-countries"),
        options
    );

    chart.render();
});