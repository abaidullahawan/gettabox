import ApexCharts from 'apexcharts';
$(document).on('turbolinks:load', function () {
    var options = {
        chart: {
            type: "area",
            height: 360,
            foreColor: "#999",
            scroller: {
                enabled: true,
                track: {
                    height: 7,
                    background: '#e0e0e0'
                },
                thumb: {
                    height: 10,
                    background: '#94E3FF'
                },
                scrollButtons: {
                    enabled: true,
                    size: 5,
                    borderWidth: 1,
                    borderColor: '#008FFB',
                    fillColor: '#008FFB'
                },
                padding: {
                    left: 30,
                    right: 20
                }
            },
            stacked: true,
            dropShadow: {
                enabled: true,
                enabledSeries: [0],
                top: -2,
                left: 2,
                blur: 5,
                opacity: 0.06
            }
        },
        colors: ['#f5f5f5', '#2962ff'],
        stroke: {
            curve: "smooth",
            width: 1
        },
        dataLabels: {
            enabled: false
        },
        series: [{
            name: 'Total Views',
            data: generateDayWiseTimeSeries(0, 18)
        }, {
            name: 'Unique Views',
            data: generateDayWiseTimeSeries(1, 18)
        }],
        markers: {
            size: 0,
            strokeColor: "#fff",
            strokeWidth: 3,
            strokeOpacity: 1,
            fillOpacity: 1,
            hover: {
                size: 5
            }
        },
        xaxis: {
            type: "datetime",
            axisBorder: {
                show: false
            },
            axisTicks: {
                show: false
            }
        },
        yaxis: {
            labels: {
                offsetX: -10,
                offsetY: -5
            },
            tooltip: {
                enabled: true
            }
        },
        grid: {
            show: true,
            borderColor: '#f6f6f7',
            padding: {
                left: -5,
                right: 5
            }
        },
        tooltip: {
            x: {
                format: "dd MMM yyyy"
            },
        },
        legend: {
            position: 'top',
            horizontalAlign: 'left'
        },
        fill: {
            type: "solid",
            fillOpacity: 0.7
        }
    };
    
    var chart = new ApexCharts(document.querySelector("#visitors-overview"), options);

    chart.render();

    function generateDayWiseTimeSeries(s, count) {
        var values = [[
            4, 3, 10, 9, 29, 19, 25, 9, 12, 7, 19, 5, 13, 9, 17, 2, 7, 5
        ], [
            2, 3, 8, 7, 22, 16, 23, 7, 11, 5, 12, 5, 10, 4, 15, 2, 6, 2
        ]];
        var i = 0;
        var series = [];
        var x = new Date("11 Aug 2018").getTime();
        while (i < count) {
            series.push([x, values[s][i]]);
            x += 86400000;
            i++;
        }
        return series;
    }
});