import 'package:flutter_test/flutter_test.dart';
import 'package:homeledger/data/models/flow_type.dart';
import 'package:homeledger/data/models/transaction.dart';
import 'package:homeledger/data/models/transaction_page.dart';
import 'package:homeledger/data/repositories/transaction_repository.dart';

import '../../support/finance_fixtures.dart';

/// 离线重算筛选与月度小计（F4⑦）。这两个函数是 `TransactionMapper.xml` 里那段
/// `<sql id="filters">` 的第二份实现，对齐得不好就是「在线看到的」与「断网看到的」两批数据。
///
/// 它们是顶层纯函数，所以这里既不建仓库也不开临时目录。
void main() {
  List<int> ids(List<Transaction> rows) => rows.map((row) => row.id).toList();

  test('日期是闭区间：起始与结束那两天本身都留下', () {
    final rows = [
      tx(id: 1, bizDate: DateTime(2026, 8, 31)),
      tx(id: 2, bizDate: DateTime(2026, 9, 1)),
      tx(id: 3, bizDate: DateTime(2026, 9, 14)),
      tx(id: 4, bizDate: DateTime(2026, 9, 15)),
    ];

    expect(
      ids(
        applyFilters(
          rows,
          const TransactionPageQuery(
            startDate: '2026-09-01',
            endDate: '2026-09-14',
          ),
        ),
      ),
      [2, 3],
    );
  });

  test('type 只留支出', () {
    final rows = [
      tx(id: 1, bizDate: DateTime(2026, 9, 1), type: FlowType.expense),
      tx(id: 2, bizDate: DateTime(2026, 9, 2), type: FlowType.income),
    ];

    expect(
      ids(
        applyFilters(rows, const TransactionPageQuery(type: FlowType.expense)),
      ),
      [1],
    );
  });

  test('类别、小类、支付方式、记录人各筛各的', () {
    final rows = [
      tx(
        id: 1,
        bizDate: DateTime(2026, 9, 10),
        categoryId: 1,
        subCategoryId: 11,
        accountId: 1,
        createdBy: 10,
      ),
      // 第二条刻意不带小类：它是「未细分」那一档
      tx(
        id: 2,
        bizDate: DateTime(2026, 9, 11),
        categoryId: 2,
        accountId: 2,
        createdBy: 11,
      ),
    ];

    expect(ids(applyFilters(rows, const TransactionPageQuery(categoryId: 2))), [
      2,
    ]);
    // SQL 里 `NULL = 3` 也不成立，所以未细分的那条匹配不上任何具体小类。
    expect(
      ids(applyFilters(rows, const TransactionPageQuery(subCategoryId: 11))),
      [1],
    );
    expect(ids(applyFilters(rows, const TransactionPageQuery(accountId: 1))), [
      1,
    ]);
    expect(ids(applyFilters(rows, const TransactionPageQuery(createdBy: 11))), [
      2,
    ]);
  });

  test('金额按「分」比：12.3 与 12.30 是同一个数', () {
    final rows = [
      tx(id: 1, bizDate: DateTime(2026, 9, 1), amount: '12.30'),
      tx(id: 2, bizDate: DateTime(2026, 9, 2), amount: '12.3'),
    ];

    expect(
      ids(applyFilters(rows, const TransactionPageQuery(amount: '12.30'))),
      [1, 2],
    );
  });

  test('金额写错时谁都不匹配，而不是抛出来', () {
    final rows = [tx(id: 1, bizDate: DateTime(2026, 9, 1), amount: '12.30')];

    // 线上传这种金额后端报 400，离线没有后端可问，一律当成筛不出东西。
    expect(
      applyFilters(rows, const TransactionPageQuery(amount: '12.3.4')),
      isEmpty,
    );
  });

  test('备注上的关键词不分大小写', () {
    final rows = [
      tx(id: 1, bizDate: DateTime(2026, 9, 1), remark: 'Starbucks 拿铁'),
    ];

    expect(
      ids(applyFilters(rows, const TransactionPageQuery(keyword: 'starbucks'))),
      [1],
    );
  });

  test('没有备注的流水在带关键词时不命中，也不抛', () {
    final rows = [tx(id: 1, bizDate: DateTime(2026, 9, 1))];

    expect(
      applyFilters(rows, const TransactionPageQuery(keyword: '星')),
      isEmpty,
    );
  });

  test('来源 AUTO 只留有 ruleId 的，MANUAL 只留没有的', () {
    final rows = [
      tx(id: 1, bizDate: DateTime(2026, 9, 1), ruleId: 77),
      tx(id: 2, bizDate: DateTime(2026, 9, 2)),
    ];

    expect(
      ids(applyFilters(rows, const TransactionPageQuery(source: 'AUTO'))),
      [1],
    );
    expect(
      ids(applyFilters(rows, const TransactionPageQuery(source: 'MANUAL'))),
      [2],
    );
  });

  test('来源是认不出的取值时不筛，而不是擅自当成 MANUAL', () {
    final rows = [
      tx(id: 1, bizDate: DateTime(2026, 9, 1), ruleId: 77),
      tx(id: 2, bizDate: DateTime(2026, 9, 2)),
    ];

    expect(
      ids(applyFilters(rows, const TransactionPageQuery(source: 'WHATEVER'))),
      [1, 2],
    );
  });

  test('空串等于没筛', () {
    final rows = [
      tx(id: 1, bizDate: DateTime(2026, 9, 1), ruleId: 77, remark: '房租'),
      tx(id: 2, bizDate: DateTime(2026, 9, 2)),
    ];

    // XML 里那几处写的是 `!= null and != ''`。
    expect(
      ids(
        applyFilters(
          rows,
          const TransactionPageQuery(type: '', keyword: '', source: ''),
        ),
      ),
      [1, 2],
    );
  });

  test('月度小计：收入减支出是结余，月份倒着排', () {
    final rows = [
      tx(
        id: 1,
        bizDate: DateTime(2026, 9, 5),
        type: FlowType.income,
        amount: '3000.00',
      ),
      tx(id: 2, bizDate: DateTime(2026, 9, 20), amount: '1200.00'),
      tx(
        id: 3,
        bizDate: DateTime(2026, 8, 11),
        type: FlowType.income,
        amount: '100.00',
      ),
      tx(id: 4, bizDate: DateTime(2026, 8, 12), amount: '250.00'),
    ];

    final summaries = summarizeByMonth(rows);

    expect(summaries.map((s) => s.month), ['2026-09', '2026-08']);
    expect(summaries.first.income, '3000.00');
    expect(summaries.first.expense, '1200.00');
    expect(summaries.first.balance, '1800.00');
    expect(summaries.first.count, 2);
    // 8 月收不抵支，结余是负的——带符号求和与「收入减支出」在这里会分家，SQL 用的是后者。
    expect(summaries.last.balance, '-150.00');
    expect(summaries.last.count, 2);
  });
}
