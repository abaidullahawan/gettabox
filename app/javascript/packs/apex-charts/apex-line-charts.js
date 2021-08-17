/*
This files table contents are outlined below >>>>>
**************************************************
01. Basic Line Chart JS
02. Line with Data Labels JS
03. Annotations Line Chart JS
04. Gradient Line Chart JS
05. Dashed Line Chart JS
06. Spline Area Charts 
*/
import ApexCharts from 'apexcharts';
import * as series from '../apex-charts/apexcharts-stock-prices.json';
$(document).on('turbolinks:load', function () {
    /* 01. Basic Line Chart JS 
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 360,
            type: 'line',
            zoom: {
                enabled: false
            }
        },
        series: [{
            name: "Desktops",
            data: [10, 41, 35, 51, 49, 62, 69, 91, 148, 160, 150, 200]
        }],
        dataLabels: {
            enabled: false
        },
        stroke: {
            curve: 'straight'
        },
        title: {
            text: 'Product Trends by Month',
            align: 'left',
            style: {
                fontSize: "13px",
                color: '#666'
            }
        },
        grid: {
            row: {
                colors: ['#f3f3f3', 'transparent'], // takes an array which will be repeated on columns
                opacity: 0.5
            },
        },
        xaxis: {
            categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-basic-line-chart"),
        options
    );

    chart.render();

    /* 02. Line with Data Labels JS 
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 365,
            type: 'line',
            shadow: {
                enabled: true,
                color: '#000',
                top: 18,
                left: 7,
                blur: 10,
                opacity: 1
            },
            toolbar: {
                show: false
            }
        },
        colors: ['#77B6EA', '#545454'],
        dataLabels: {
            enabled: true,
        },
        stroke: {
            curve: 'smooth'
        },
        series: [{
                name: "High - 2019",
                data: [28, 29, 33, 36, 32, 32, 33, 28, 29, 33, 36, 32],
            },
            {
                name: "Low - 2019",
                data: [12, 11, 14, 18, 17, 13, 13, 12, 11, 14, 18, 17]
            }
        ],
        title: {
            text: 'Average High & Low Revenue',
            align: 'left',
            style: {
                fontSize: "13px",
                color: '#666'
            }
        },
        grid: {
            borderColor: '#e7e7e7',
            row: {
                colors: ['#f3f3f3', 'transparent'], // takes an array which will be repeated on columns
                opacity: 0.5
            },
        },
        markers: {
            size: 6
        },
        xaxis: {
            categories: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct','Nov', 'Dec'],
            title: {
                text: 'Month'
            }
        },
        legend: {
            position: 'top',
            horizontalAlign: 'right',
            floating: true,
            offsetY: -10,
            offsetX: -5
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-line-with-data-labels"),
        options
    );

    chart.render();

    /* 03. Annotations Line Chart JS 
    -------------------------------------------------*/
    var options = {
        annotations: {
            yaxis: [
                {
                    y: 8200,
                    borderColor: "#00E396",
                    label: {
                        borderColor: "#00E396",
                        style: {
                            color: "#fff",
                            background: "#00E396"
                        },
                        text: "Y Axis Annotation"
                    }
                }
            ],
            xaxis: [
                {
                    // in a datetime series, the x value should be a timestamp, just like it is generated below
                    x: new Date("11/17/2017").getTime(),
                    strokeDashArray: 0,
                    borderColor: "#775DD0",
                    label: {
                        borderColor: "#775DD0",
                        style: {
                            color: "#fff",
                            background: "#775DD0"
                        },
                        text: "X Axis Anno Vertical"
                    }
                },
                {
                    x: new Date("03 Dec 2017").getTime(),
                    borderColor: "#FEB019",
                    label: {
                        borderColor: "#FEB019",
                        style: {
                            color: "#fff",
                            background: "#FEB019"
                        },
                        orientation: "horizontal",
                        text: "X Axis Anno Horizonal"
                    }
                }
            ],
            points: [
                {
                    x: new Date("27 Nov 2017").getTime(),
                    y: 8500.9,
                    marker: {
                        size: 8,
                        fillColor: "#fff",
                        strokeColor: "#2698FF",
                        radius: 2
                    },
                    label: {
                        borderColor: "#FF4560",
                        offsetY: 0,
                        style: {
                            color: "#fff",
                            background: "#FF4560"
                        },
                        text: "Point Annotation (XY)"
                    }
                }
            ]
        },
        chart: {
            height: 380,
            type: "line",
            id: "areachart-2"
        },
        dataLabels: {
            enabled: false
        },
        stroke: {
            curve: "straight"
        },
        series: [
            {
                data: series.monthDataSeries1.prices
            }
        ],
        title: {
            text: "Line with Annotations",
            align: "left",
            style: {
                fontSize: "13px",
                color: '#666'
            }
        },
        labels: series.monthDataSeries1.dates,
        xaxis: {
            type: "datetime"
        }
    };

    var chart = new ApexCharts(document.querySelector("#apex-annotations-chart"), options);

    chart.render();

    /* 04. Gradient Line Chart JS 
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 350,
            type: 'line',
            shadow: {
                enabled: false,
                color: '#bbb',
                top: 3,
                left: 2,
                blur: 3,
                opacity: 1
            },
        },
        stroke: {
            width: 7,   
            curve: 'smooth'
        },
        series: [{
            name: 'Likes',
            data: [4, 3, 10, 9, 29, 19, 22, 9, 12, 7, 19, 5, 13, 9, 17, 2, 7, 5]
        }],
        xaxis: {
            type: 'datetime',
            categories: ['1/11/2000', '2/11/2000', '3/11/2000', '4/11/2000', '5/11/2000', '6/11/2000', '7/11/2000', '8/11/2000', '9/11/2000', '10/11/2000', '11/11/2000', '12/11/2000', '1/11/2001', '2/11/2001', '3/11/2001','4/11/2001' ,'5/11/2001' ,'6/11/2001'],
        },
        title: {
            text: 'Social Media',
            align: 'left',
            style: {
                fontSize: "13px",
                color: '#666'
            }
        },
        fill: {
            type: 'gradient',
            gradient: {
                shade: 'dark',
                gradientToColors: [ '#FDD835'],
                shadeIntensity: 1,
                type: 'horizontal',
                opacityFrom: 1,
                opacityTo: 1,
                stops: [0, 100, 100, 100]
            },
        },
        markers: {
            size: 4,
            opacity: 0.9,
            colors: ["#FFA41B"],
            strokeColor: "#fff",
            strokeWidth: 2,
            hover: {
                size: 7,
            }
        },
        yaxis: {
            min: -10,
            max: 40,
            title: {
                text: 'Engagement',
            },                
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-gradient-chart"),
        options
    );

    chart.render();

    /* 05. Dashed Line Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 350,
            type: 'line',
            zoom: {
                enabled: false
            },
        },
        dataLabels: {
            enabled: false
        },
        stroke: {
            width: [5, 7, 5],
            curve: 'straight',
            dashArray: [0, 8, 5]
        },
        series: [{
                name: "Session Duration",
                data: [45, 52, 38, 24, 33, 26, 21, 20, 6, 8, 15, 10]
            },
            {
                name: "Page Views",
                data: [35, 41, 62, 42, 13, 18, 29, 37, 36, 51, 32, 35]
            },
            {
                name: 'Total Visits',
                data: [87, 57, 74, 99, 75, 38, 62, 47, 82, 56, 45, 47]
            }
        ],
        title: {
            text: 'Page Statistics',
            align: 'left'
        },
        legend: {
            tooltipHoverFormatter: function(val, opts) {
                return val + ' - ' + opts.w.globals.series[opts.seriesIndex][opts.dataPointIndex] + ''
            },
            offsetY: -10,
        },
        markers: {
            size: 0,
            hover: {
                sizeOffset: 6
            }
        },
        xaxis: {
            categories: ['01 Jan', '02 Jan', '03 Jan', '04 Jan', '05 Jan', '06 Jan', '07 Jan', '08 Jan', '09 Jan',
                '10 Jan', '11 Jan', '12 Jan'
            ],
        },
        tooltip: {
            y: [{
                title: {
                    formatter: function (val) {
                        return val + " (mins)"
                    }
                }
            }, {
                title: {
                    formatter: function (val) {
                        return val + " per session"
                    }
                }
            }, {
                title: {
                    formatter: function (val) {
                        return val;
                    }
                }
            }]
        },
        grid: {
            borderColor: '#f1f1f1',
        },
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-dashed-linechart"),
        options
    );
    chart.render();
});