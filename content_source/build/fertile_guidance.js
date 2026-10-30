// Wording of the "Canh ngày thụ thai" features (cycle predictions, Hôm nay
// card). The app reads it from assets/content/fertile_guidance.json; the
// doctor review packet reads the same file.
// No percentage chance of pregnancy, no baby sex selection, no failure or
// month count, no pressure.
const g = (group, id, text) => ({ id, group, text });

module.exports = {
  sources: [
    'ASRM, Optimizing natural fertility (2021): https://www.asrm.org/practice-guidance/practice-committee-documents/optimizing-natural-fertility-a-committee-opinion-2021',
  ],
  items: [
    g('Thẻ Hôm nay', 'title', 'Khả năng thụ thai hôm nay'),
    g('Mức', 'level_low', 'Thấp'),
    g('Mức', 'level_high', 'Cao'),
    g('Mức', 'level_peak', 'Đỉnh'),
    g('Mức', 'estimate_suffix', '(ước tính)'),
    g('Thẻ Hôm nay', 'message_low', 'Hôm nay nằm ngoài khoảng ngày dễ thụ thai dự đoán.'),
    g('Thẻ Hôm nay', 'message_high', 'Hôm nay nằm trong khoảng ngày dễ thụ thai dự đoán.'),
    g('Thẻ Hôm nay', 'message_peak', 'Hôm nay nằm trong những ngày dễ thụ thai nhất của khoảng dự đoán.'),
    g('Dự đoán', 'window_label', 'Khoảng ngày dễ thụ thai dự đoán'),
    g('Độ tin cậy', 'confidence_label', 'Độ tin cậy'),
    g('Độ tin cậy', 'confidence_low', 'Thấp'),
    g('Độ tin cậy', 'confidence_medium', 'Trung bình'),
    g('Độ tin cậy', 'confidence_note_insufficient', 'Cần ít nhất 3 kỳ kinh để ước tính tốt hơn, nên ngày dự đoán có thể lệch nhiều.'),
    g('Độ tin cậy', 'confidence_note_irregular', 'Chu kỳ của bạn chưa đều nên ngày dự đoán có thể lệch nhiều.'),
    g('Độ tin cậy', 'confidence_note_medium', 'Chu kỳ gần đây khá đều, nhưng ngày thực tế vẫn có thể lệch.'),
    g('Dự đoán', 'ovulation_note', 'Ngày rụng trứng chỉ được ước tính, khoảng 14 ngày trước kỳ kinh tiếp theo, và có thể khác với thực tế.'),
    g('Dự đoán', 'ovulation_in_range', 'Trong khoảng dự đoán'),
    g('Gợi ý', 'frequency', 'Trong khoảng ngày này, quan hệ khoảng 1-2 ngày một lần là đủ. Hai bạn cứ chọn nhịp phù hợp với mình, không cần kiêng trước đó.'),
    g('Lưu ý', 'outside_range_note', 'Có chu kỳ ngắn hơn 21 ngày hoặc dài hơn 35 ngày. Bạn có thể trao đổi thêm với bác sĩ khi tiện.'),
    g('Lưu ý', 'not_contraception', 'Đây chỉ là ước tính từ dữ liệu bạn đã ghi, không dùng để tránh thai.'),
  ],
};
