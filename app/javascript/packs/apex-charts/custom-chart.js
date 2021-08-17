import ApexCharts from 'apexcharts';
$(document).on('turbolinks:load', function () {
    // Total sales chart
    var options = {
        chart: {
            height: 380,
            type: "line"
        },
        colors:['#2962ff', '#886cff'],
        series: [
            {
                name: 'Online',
                data: [45, 52, 38, 45, 45, 52, 38, 45, 45, 52, 38, 45]
            },
            {
                name: 'Ofline',
                data: [12, 42, 68, 33, 12, 42, 68, 33, 12, 42, 68, 33,]
            }
        ],
        labels: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "July", "Aug", "Sep", "Oct", "Nov", "Dec"],
        markers: {
            size: 0
        },
        stroke: {
            width: 3,
            curve: 'smooth',
            lineCap: 'round'
        },
        legend: {
            position: 'top',
        },
        grid: {
            show: true,
            borderColor: '#f6f6f7',
        },
        xaxis: {
            labels: {
                style: {
                    colors: '#686c71',
                    fontSize: '12px',
                },
            },
            axisBorder: {
                show: true,
                color: '#f6f6f7',
                height: 1,
                width: '100%',
                offsetX: 0,
                offsetY: 0
            },
        },
        yaxis: {
            labels: {
                style: {
                    color: '#686c71',
                    fontSize: '12px',
                },
            },
            axisBorder: {
                show: true,
                color: '#f6f6f7',
            },
        }
    };
    var chart = new ApexCharts(document.querySelector("#total-sales-chart"), options);
    chart.render();

    // Weekly Target
    var options = {
        chart: {
            height: 370,
            type: 'radialBar',
        },
        colors:['#2962ff'],
        plotOptions: {
            radialBar: {
                hollow: {
                    size: '80%',
                },
                dataLabels: {
                    name: {
                        show: true,
                        fontSize: '30px',
                    },
                    value: {
                        show: true,
                    }
                },
            },
        },
        series: [85],
        labels: ['$20,456'],
    }

    var chart = new ApexCharts(
        document.querySelector("#weekly-target-chart"),
        options
    );

    chart.render();
    
    // Monthly hours Target
    var options = {
        chart: {
            height: 400,
            type: 'radialBar',
        },
        colors:['#2962ff'],
        plotOptions: {
            radialBar: {
                hollow: {
                    size: '80%',
                },
                dataLabels: {
                    name: {
                        show: true,
                        fontSize: '30px',
                    },
                    value: {
                        show: true,
                    }
                },
            },
        },
        series: [70],
        labels: ['12,000'],
    }

    var chart = new ApexCharts(
        document.querySelector("#monthly-hours-target"),
        options
    );

    chart.render();
});