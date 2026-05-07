import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/order.dart';
import '../models/product.dart';

class ExcelService {

  // قراءة المنتجات من ملف Excel
  Future<List<Product>> readProductsFromExcel(String filePath) async {
    List<Product> products = [];

    var bytes = File(filePath).readAsBytesSync();
    Excel excel = Excel.decodeBytes(bytes);

    Sheet sheet = excel.tables.values.first;

    // تحديد الصف الأول كرؤوس
    int startRow = 0;
    if (sheet.rows.isNotEmpty) {
      var firstRow = sheet.rows[0];
      if (firstRow.isNotEmpty &&
          (firstRow[0]?.value?.toString().contains('اسم') ?? false)) {
        startRow = 1;
      }
    }

    for (int i = startRow; i < sheet.rows.length; i++) {
      var row = sheet.rows[i];

      if (row.length >= 2) {
        String name = row[0]?.value?.toString() ?? '';
        double price = _parseDouble(row[1]?.value);
        int quantity = row.length > 2 ? _parseInt(row[2]?.value) : 0;
        String category = row.length > 3 ? row[3]?.value?.toString() ?? '' : '';
        String description = row.length > 4 ? row[4]?.value?.toString() ?? '' : '';

        if (name.isNotEmpty && price > 0) {
          products.add(Product(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            name: name,
            price: price,
            quantity: quantity,
            description: description,
            category: category,
            imageUrl: '',
            createdAt: DateTime.now(),
          ));
        }
      }
    }

    return products;
  }

  // تصدير الطلبات إلى Excel
  Future<String> exportOrdersToExcel(List<OrderModel> orders) async {
    Excel excel = Excel.createExcel();
    Sheet sheetObject = excel['الطلبات'];

    // تنسيق الرؤوس
    CellStyle headerStyle = CellStyle(
      bold: true,
      backgroundColorHex:ExcelColor.cyan ,
      fontColorHex:ExcelColor.cyan50,
    );

    // رؤوس الأعمدة
    List<String> headers = [
      'رقم الطلب', 'اسم العميل', 'رقم الجوال', 'العنوان',
      'عدد المنتجات', 'الإجمالي', 'الحالة', 'التاريخ'
    ];

    for (int i = 0; i < headers.length; i++) {
      var  cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i] as CellValue?;
      cell.cellStyle = headerStyle;
    }

    // إضافة البيانات
    for (int i = 0; i < orders.length; i++) {
      OrderModel order = orders[i];
      int rowIndex = i + 1;

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = order.id.substring(0, 12) as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = order.userName as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = order.userPhone as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = order.userAddress as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = order.items.length as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex)).value = order.totalPrice as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex)).value = order.getStatusText() as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex)).value = _formatDate(order.createdAt) as CellValue?;
    }

    // حفظ الملف
    var fileBytes = await excel.encode();
    if (fileBytes == null) throw Exception('Failed to encode Excel');

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/orders_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await File(filePath).writeAsBytes(fileBytes);

    return filePath;
  }

  // تصدير المنتجات إلى Excel
  Future<String> exportProductsToExcel(List<Product> products) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['المنتجات'];

    CellStyle headerStyle = CellStyle(bold: true, backgroundColorHex: ExcelColor.cyan100, fontColorHex: ExcelColor.cyan600);

    List<String> headers = ['اسم المنتج', 'السعر', 'الكمية', 'التصنيف', 'الوصف'];

    for (int i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i] as CellValue?;
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < products.length; i++) {
      var product = products[i];
      int rowIndex = i + 1;

      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = product.name as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = product.price as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = product.quantity as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = product.category as CellValue?;
      sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = product.description as CellValue?;
    }

    var fileBytes = await excel.encode();
    if (fileBytes == null) throw Exception('Failed to encode Excel');

    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    await File(filePath).writeAsBytes(fileBytes);

    return filePath;
  }

  // مشاركة الملف
  Future<void> shareExcelFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'تقرير النظام');
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}