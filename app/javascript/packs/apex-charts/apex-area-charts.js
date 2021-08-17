/*
This files table contents are outlined below >>>>>
**************************************************
01. Basic Area Chart JS
02. Spline Area Chart JS
03. Negative Area Chart JS
04. Stacked Area Chart JS
*/
import ApexCharts from 'apexcharts';
import * as series from '../apex-charts/apexcharts-stock-prices.json';
$(document).on('turbolinks:load', function () {
    /* 01. Basic Area Chart JS 
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 374,
            type: 'area',
            zoom: {
                enabled: false
            }
        },
        dataLabels: {
            enabled: false
        },
        stroke: {
            curve: 'straight'
        },
        series: [{
            name: "STOCK ABC",
            data: series.monthDataSeries1.prices
        }],
        title: {
            text: 'Fundamental Analysis of Stocks',
            align: 'left',
            style: {
                fontSize: "13px",
                color: '#666'
            }
        },
        subtitle: {
            text: 'Price Movements',
            align: 'left'
        },
        labels: series.monthDataSeries1.dates,
        xaxis: {
            type: 'datetime',
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
            opposite: true,
            labels: {
                style: {
                    color: '#686c71',
                    fontSize: '12px',
                },
            },
            axisBorder: {
                show: false,
                color: '#f6f6f7',
            },
        },
        legend: {
            horizontalAlign: 'left'
        },
        grid: {
            show: true,
            borderColor: '#f6f6f7',
        },
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-basic-area-chart"),
        options
    );

    chart.render();

    /* 02. Spline Area Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 350,
            type: 'area',
        },
        dataLabels: {
            enabled: false
        },
        stroke: {
            curve: 'smooth'
        },
        series: [{
            name: 'New Sales',
            data: [31, 40, 28, 51, 42, 109, 100]
        }, {
            name: 'Existing Sales',
            data: [11, 32, 45, 32, 34, 52, 41]
        }],
        xaxis: {
            type: 'datetime',
            categories: ["2018-09-19T00:00:00", "2018-09-19T01:30:00", "2018-09-19T02:30:00", "2018-09-19T03:30:00", "2018-09-19T04:30:00", "2018-09-19T05:30:00", "2018-09-19T06:30:00"],                
        },
        tooltip: {
            x: {
                format: 'dd/MM/yy HH:mm'
            },
        },
        legend: {
            offsetY: -10,
        },
    }
    
    var chart = new ApexCharts(
        document.querySelector("#apex-spline-area-chart"),
        options
    );
    
    chart.render();

    /* 03. Negative Area Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 350,
            type: 'area',
            // zoom: {
            //     enabled: false
            // }
        },
        dataLabels: {
            enabled: false
        },
        stroke: {
            curve: 'straight'
        },
        series: [{
            name: 'North',
            data: [{
                    x: 1996,
                    y: 322
                },
                {
                    x: 1997,
                    y: 324
                },
                {
                    x: 1998,
                    y: 329
                },
                {
                    x: 1999,
                    y: 342
                },
                {
                    x: 2000,
                    y: 348
                },
                {
                    x: 2001,
                    y: 334
                },
                {
                    x: 2002,
                    y: 325
                },
                {
                    x: 2003,
                    y: 316
                },
                {
                    x: 2004,
                    y: 318
                },
                {
                    x: 2005,
                    y: 330
                },
                {
                    x: 2006,
                    y: 355
                },
                {
                    x: 2007,
                    y: 366
                },
                {
                    x: 2008,
                    y: 337
                },
                {
                    x: 2009,
                    y: 352
                },
                {
                    x: 2010,
                    y: 377
                },
                {
                    x: 2011,
                    y: 383
                },
                {
                    x: 2012,
                    y: 344
                },
                {
                    x: 2013,
                    y: 366
                },
                {
                    x: 2014,
                    y: 389
                },
                {
                    x: 2015,
                    y: 334
                }
            ]
        }, {
            name: 'South',
            data: [

                {
                    x: 1996,
                    y: 162
                },
                {
                    x: 1997,
                    y: 90
                },
                {
                    x: 1998,
                    y: 50
                },
                {
                    x: 1999,
                    y: 77
                },
                {
                    x: 2000,
                    y: 35
                },
                {
                    x: 2001,
                    y: -45
                },
                {
                    x: 2002,
                    y: -88
                },
                {
                    x: 2003,
                    y: -120
                },
                {
                    x: 2004,
                    y: -156
                },
                {
                    x: 2005,
                    y: -123
                },
                {
                    x: 2006,
                    y: -88
                },
                {
                    x: 2007,
                    y: -66
                },
                {
                    x: 2008,
                    y: -45
                },
                {
                    x: 2009,
                    y: -29
                },
                {
                    x: 2010,
                    y: -45
                },
                {
                    x: 2011,
                    y: -88
                },
                {
                    x: 2012,
                    y: -132
                },
                {
                    x: 2013,
                    y: -146
                },
                {
                    x: 2014,
                    y: -169
                },
                {
                    x: 2015,
                    y: -184
                }
            ]
        }],
        title: {
            text: 'Area with Negative Values',
            align: 'left',
            style: {
                fontSize: '13px'
            }
        },
        xaxis: {
            type: 'datetime',
            axisBorder: {
                show: false
            },
            axisTicks: {
                show: false
            }
        },
        yaxis: {
            tickAmount: 4,
            floating: false,

            labels: {
                style: {
                    color: '#8e8da4',
                },
                offsetY: -7,
                offsetX: 0,
            },
            axisBorder: {
                show: false,
            },
            axisTicks: {
                show: false
            }
        },
        fill: {
            type: [ 'gradient', 'solid'],
            opacity: 1,
        },
        tooltip: {
            x: {
                format: "yyyy",
            },
            fixed: {
                enabled: false,
                position: 'topRight'
            }
        },
        grid: {
            yaxis: {
                lines: {
                    offsetX: -30
                }
            },
            padding: {
                left: 20
            }
        },
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-negative-area-chart"),
        options
    );

    chart.render();

    /* 04. Negative Area Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 350,
            type: 'area',
            stacked: true,
            events: {
                selection: function(chart, e) {
                    console.log(new Date(e.xaxis.min) )
                }
            },
        },
        colors: ['#008FFB', '#00E396', '#CED4DC'],
        dataLabels: {
            enabled: false
        },
        stroke: {
            curve: 'smooth'
        },
        series: [{
            name: 'South',
            data: generateDayWiseTimeSeries(new Date('11 Feb 2017 GMT').getTime(), 20, {
                min: 10,
                max: 60
            })
        },
        {
            name: 'North',
            data: generateDayWiseTimeSeries(new Date('11 Feb 2017 GMT').getTime(), 20, {
                min: 10,
                max: 20
            })
        },
        {
            name: 'Central',
            data: generateDayWiseTimeSeries(new Date('11 Feb 2017 GMT').getTime(), 20, {
                min: 10,
                max: 15
            })
        }
        ],
        fill: {
        type: 'gradient',
            gradient: {
                opacityFrom: 0.6,
                opacityTo: 0.8,
            }
        },
        legend: {
            position: 'top',
            horizontalAlign: 'left'
        },
        xaxis: {
            type: 'datetime'
        },
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-stacked-area-chart"),
        options
    );

    chart.render();

    function generateDayWiseTimeSeries(baseval, count, yrange) {
        var i = 0;
        var series = [];
        while (i < count) {
            var x = baseval;
            var y = Math.floor(Math.random() * (yrange.max - yrange.min + 1)) + yrange.min;
            series.push([x, y]);
            baseval += 86400000;
            i++;
        }
        return series;
    }
});