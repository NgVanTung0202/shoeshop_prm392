import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';
import '../widgets/admin_drawer.dart';

class AdminDashboardScreen extends StatelessWidget {
  AdminDashboardScreen({super.key});

  final FirestoreService _fs = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(selected: AdminMenuItem.dashboard),
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Báo Cáo Thống Kê', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: _fs.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Chưa có dữ liệu đơn hàng"));
          }

          final orders = snapshot.data!;
          double totalRevenue = 0;
          for (var o in orders) {
            totalRevenue += o.totalPrice;
          }

          // Nhóm đơn hàng theo ngày trong 7 ngày gần nhất
          final today = DateTime.now();
          final startOfToday = DateTime(today.year, today.month, today.day);
          
          final Map<DateTime, double> revenueByDate = {};
          final Map<DateTime, int> ordersByDate = {};
          
          for (int i = 0; i < 7; i++) {
            final date = startOfToday.subtract(Duration(days: i));
            revenueByDate[date] = 0;
            ordersByDate[date] = 0;
          }

          for (var o in orders) {
            final orderDate = DateTime(o.createdAt.year, o.createdAt.month, o.createdAt.day);
            if (revenueByDate.containsKey(orderDate)) {
              revenueByDate[orderDate] = revenueByDate[orderDate]! + o.totalPrice;
              ordersByDate[orderDate] = ordersByDate[orderDate]! + 1;
            }
          }

          final sortedDates = revenueByDate.keys.toList()..sort();
          List<BarChartGroupData> barGroups = [];
          
          for (int i = 0; i < sortedDates.length; i++) {
            final date = sortedDates[i];
            barGroups.add(BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: revenueByDate[date]!,
                  color: Colors.blue,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                )
              ],
            ));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thẻ Tổng quan
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Tổng Đơn Hàng", 
                        "${orders.length}", 
                        Icons.shopping_bag, 
                        Colors.orange
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "Tổng Doanh Thu", 
                        NumberFormat.currency(locale: 'vi', symbol: 'đ').format(totalRevenue),
                        Icons.monetization_on, 
                        Colors.green
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),
                const Text("Doanh thu 7 ngày qua", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                // Chart
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value >= 0 && value < sortedDates.length) {
                                final date = sortedDates[value.toInt()];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10)),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: barGroups,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
        ],
      ),
    );
  }
}
