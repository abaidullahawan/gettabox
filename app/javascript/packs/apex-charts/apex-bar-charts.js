/*
This files table contents are outlined below >>>>>
**************************************************
01. Basic Bar Chart JS
02. Basic Grouped Chart JS
03. Basic Stacked Bar Chart JS
04. Stacked Bars 100% Chart JS
05. Custom DataLabels Bar Chart JS
*/
import ApexCharts from 'apexcharts';
$(document).on('turbolinks:load', function () {
    /* 01. Basic Bar Chart JS 
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 360,
            type: 'bar',
        },
        plotOptions: {
            bar: {
                horizontal: true,
            }
        },
        dataLabels: {
            enabled: false
        },
        series: [{
            data: [400, 430, 448, 470, 540, 580, 690, 1100, 1200, 1380]
        }],
        xaxis: {
            categories: ['South Korea', 'Canada', 'United Kingdom', 'Netherlands', 'Italy', 'France', 'Japan', 'United States', 'China', 'Germany'],
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-basic-bar-chart"),
        options
    );
    
    chart.render();

    /* 02. Basic Grouped Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 460,
            type: 'bar',
        },
        plotOptions: {
            bar: {
                horizontal: true,
                dataLabels: {
                    position: 'top',
                },
            }  
        },
        dataLabels: {
            enabled: true,
            offsetX: -6,
            style: {
                fontSize: '12px',
                colors: ['#fff']
            }
        },
        stroke: {
            show: true,
            width: 1,
            colors: ['#fff']
        },
        series: [{
            data: [44, 55, 41, 64, 22, 43, 21]
        },{
            data: [53, 32, 33, 52, 13, 44, 32]
        }],
        xaxis: {
            categories: [2001, 2002, 2003, 2004, 2005, 2006, 2007],
        },
        legend: {
            offsetY: -10,
        },
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-grouped-chart"),
        options
    );
    
    chart.render();

    /* 03. Basic Stacked Bar Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 350,
            type: 'bar',
            stacked: true,
        },
        plotOptions: {
            bar: {
                horizontal: true,
            },
        },
        stroke: {
            width: 1,
            colors: ['#fff']
        },
        series: [{
            name: 'Marine Sprite',
            data: [44, 55, 41, 37, 22, 43, 21]
        },{
            name: 'Striking Calf',
            data: [53, 32, 33, 52, 13, 43, 32]
        },{
            name: 'Tank Picture',
            data: [12, 17, 11, 9, 15, 11, 20]
        },{
            name: 'Bucket Slope',
            data: [9, 7, 5, 8, 6, 9, 4]
        },{
            name: 'Reborn Kid',
            data: [25, 12, 19, 32, 25, 24, 10]
        }],
        title: {
            text: 'Fiction Books Sales'
        },
        xaxis: {
            categories: [2008, 2009, 2010, 2011, 2012, 2013, 2014],
            labels: {
                formatter: function(val) {
                    return val + "K"
                }
            }
        },
        yaxis: {
            title: {
                text: undefined
            },
        },
        tooltip: {
            y: {
                formatter: function(val) {
                    return val + "K"
                }
            }
        },
        fill: {
            opacity: 1
            
        },
        legend: {
            position: 'top',
            horizontalAlign: 'left',
            
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-stacked-bar-chart"),
        options
    );
    
    chart.render();

    /* 04. Stacked Bars 100% Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 350,
            type: 'bar',
            stacked: true,
            stackType: '100%'
        },
        plotOptions: {
            bar: {
                horizontal: true,
            },
            
        },
        stroke: {
            width: 1,
            colors: ['#fff']
        },
        series: [{
            name: 'Marine Sprite',
            data: [44, 55, 41, 37, 22, 43, 21]
        },{
            name: 'Striking Calf',
            data: [53, 32, 33, 52, 13, 43, 32]
        },{
            name: 'Tank Picture',
            data: [12, 17, 11, 9, 15, 11, 20]
        },{
            name: 'Bucket Slope',
            data: [9, 7, 5, 8, 6, 9, 4]
        },{
            name: 'Reborn Kid',
            data: [25, 12, 19, 32, 25, 24, 10]
        }],
        title: {
            text: '100% Stacked Bar'
        },
        xaxis: {
            categories: [2008, 2009, 2010, 2011, 2012, 2013, 2014],
        },
        tooltip: {
                y: {
                    formatter: function(val) {
                    return val + "K"
                }
            }
        },
        fill: {
            opacity: 1
        },
        legend: {
            position: 'top',
            horizontalAlign: 'left',
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-stacked-bars-100-chart"),
        options
    );
    
    chart.render();

    /* 05. Custom DataLabels Bar Chart JS
    -------------------------------------------------*/
    var options = {
        chart: {
            height: 380,
            type: 'bar'
        },
        plotOptions: {
            bar: {
                barHeight: '100%',
                distributed: true,
                horizontal: true,
                dataLabels: {
                    position: 'bottom'
                },
            }
        },
        colors: ['#33b2df', '#546E7A', '#d4526e', '#13d8aa', '#A5978B', '#2b908f', '#f9a3a4', '#90ee7e', '#f48024', '#69d2e7'],
        dataLabels: {
            enabled: true,
            textAnchor: 'start',
            style: {
                colors: ['#fff']
            },
            formatter: function(val, opt) {
                return opt.w.globals.labels[opt.dataPointIndex] + ":  " + val
            },
            offsetX: 0,
            dropShadow: {
                enabled: true
            }
        },
        series: [{
            data: [400, 430, 448, 470, 540, 580, 690, 1100, 1200, 1380]
        }],
        stroke: {
            width: 1,
            colors: ['#fff']
        },
        xaxis: {
            categories: ['South Korea', 'Canada', 'United Kingdom', 'Netherlands', 'Italy', 'France', 'Japan', 'United States', 'China', 'India'],
        },
        yaxis: {
            labels: {
                show: false
            }
        },
        title: {
            text: 'Custom DataLabels',
            align: 'center',
            floating: true
        },
        subtitle: {
            text: 'Category Names as DataLabels inside bars',
            align: 'center',
        },
        tooltip: {
            theme: 'dark',
            x: {
                show: false
            },
            y: {
                title: {
                    formatter: function() {
                        return ''
                    }
                }
            }
        }
    }

    var chart = new ApexCharts(
        document.querySelector("#apex-custom-datalabels-bar"),
        options
    );
    
    chart.render();
});