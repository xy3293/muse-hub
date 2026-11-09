# T-001 代币化美股研究

- **编号**：T-001
- **标题**：代币化美股研究
- **负责人**：node-1
- **研究日期**：2026-11-10（星期二）
- **数据截止**：除特别注明外，引用来源的抓取 / 发布日期见各节与文末来源清单；市场规模类数字变化很快，以注明日期为准
- **文件**：`results/node-1/T-001-tokenized-us-stocks.md`
- **Issue**：https://github.com/xy3293/muse-hub/issues/1

> 本报告不是投资建议。代币化美股是新产品，规则、费率与可及地区变化很快，下单前必须以发行方与平台当时的官方页面为准复核。

---

## 结论先行（给 Chen 的答案）

**能不能玩：可以小资金试水，但不是“换个地方买美股正股”。**

代币化美股买到的是价格敞口，不是正股本身。xStocks 与 Ondo Stocks 都是离岸发行、1:1 抵押正股的追踪凭证 / 票据，持有人没有投票权、没有对上市公司的直接权利，一般也不能直接赎回正股；零售用户的主要退出方式是在二级市场卖出。它的唯一真实优势是交易时间与上链转移：美股盘外、周末也能报价、可碎片化、可提到钱包、可作抵押或进 DeFi；代价是点差、盘外溢价、发行方与托管链风险，以及美国、英国、加拿大、澳大利亚等地被排除在外。

**现阶段是否适合小资金试水：适合“学习型小额试水”，不适合当作正股的长期替代仓位。**

前提有三条，缺一条就先别买：

1. **先确认身份与所在地能用**——xStocks 与 Ondo Stocks 均不对美国人士开放，另有英国、加拿大、澳大利亚等排除地区；中国内地用户还面临本地监管限制（见第 2 节与第 7 节）。
2. **只用现货、只买流动性最好的大票 / 宽基 ETF、只在美股交易时段买**——例如 SPYx、QQQx、AAPLx、NVDAx、TSLAx；避开周末、深夜与小票。
3. **金额小到亏完也不影响生活，并且先算清点差**——Kraken App 用 USD/USD G 买 xStocks 官方称无交易费，但价格里含点差，风险披露页写明买入价为市价 +1.0% 点差（见第 3 节，两个官方口径不一致，需下单前在 App 内实测核对）；不要一上来就用 3 倍保证金或 20 倍永续做空。

**如果试，第一步建议（只做这一步，不要一次做完所有事）：**

> 先在 Kraken 完成实名认证并在 App 内确认自己所在地区能看到 xStocks；然后在美股开盘时段（美东 9:30–16:00），用 USD 买一笔很小的 SPYx（例如 100 美元量级，仅为示例金额，可自行调低），下单前截图记录 Kraken 报价与同期 SPY 实时价，算出实际溢价 / 点差；持有一周，观察分红再投资后余额变化、周末价格如何偏离周五收盘价、卖出时点差多大。能接受这套成本与偏离，再考虑是否加仓；不能接受，就停在“已验证成本”这一步，不要用杠杆追回来。

**不适合的情况**：想长期持有收现金分红、想投票、想在券商里享受 SIPC 式保障、想随时按正股价格精确成交、人在被排除地区、或只能接受正股券商的合规与税务确定性——这些需求都应直接买正股，而不是买代币。

---

## 阅读方法：事实、推断与“未验证”

- **事实**：有官方页面或可复核来源支撑的陈述，文内贴来源链接并注明日期。
- **推断**：从事实出发的判断，文内明确写“推断”。
- **未验证 / 未查到**：查过但没找到可靠来源，或来源之间冲突无法确认，文内直接写明，不猜数字。
- 同一数字若不同来源、不同日期说法不同，本报告并列写出，不强行统一。

---

## 1. 发行机制：谁发行、谁托管、能不能赎回正股或现金

### 1.1 xStocks（Backed Finance / Kraken）

**事实：**

- 发行方是 Backed Assets (JE) Limited，一家泽西岛私人有限公司，专为发行与赎回 xStocks 而设的特殊目的实体（SPV），在泽西金融服务委员会注册；产品在 Kraken 上由 Payward Digital Solutions Ltd.（PDSL，百慕大金融管理局许可）向合资格客户提供。来源：Kraken xStocks 页面（2026-11-09 抓取）与 Kraken 风险披露页。
  - https://www.kraken.com/gb/xstocks
  - https://www.kraken.com/legal/xstocks
- 法律性质是追踪凭证（tracker certificate），不是正股本身。Kraken 官方 FAQ 明确：xStocks 不赋予投票权等股东权利，只提供对标的资产的价格敞口。来源同上。
- 每一枚 xStock 由 1:1 的正股或 ETF 抵押，标的由受监管托管方持有。Kraken 官方说法是“创建 xStock 时即在股市买入标的股票并由受监管托管方持有，直至 xStock 存续结束”。第三方研究（2026 年 10 月，引用 xStocks 招股文件）称美国经纪与托管方为 Alpaca Securities LLC（美国注册经纪商、FINRA 会员）与 Alpaca Crypto LLC，另有欧洲合资格标的由瑞士 InCore 与 Maerki Baumann 等托管；抵押品放在隔离、非混同的子账户，并有三方账户控制协议与独立担保代理人。来源：
  - https://www.kraken.com/gb/xstocks
  - https://coinpaprika.com/education/tokenized-stocks-explained
  - https://eco.com/support/en/articles/15083158-kraken-xstocks-explained
- 另有第三方称 Backed 披露了 Lloyd's of London 最高 1.75 亿美元的托管损失补充保险（数据截至 2026 年 10 月）。该数字来自二手汇总，未在本次核查中看到 Kraken / Backed 官方页面的原文，**列为未验证**，不要当作保障承诺。
  - https://coinpaprika.com/education/tokenized-stocks-explained
- 链：最初在 Solana 上线，后扩展到 Ethereum、BNB Chain、Arbitrum、Mantle、TON、Ink 等 10 条以上链（Kraken 页面称“10+ 支持的区块链”，包括 Solana、Ethereum 与 BNB Chain）。来源：
  - https://www.kraken.com/gb/xstocks
- 上线时间：多方均称 2025 年 6 月上线，首批约 60 只；但具体日期说法不一（有来源称 2025 年 5 月 22 日，有来源称 2025 年 6 月 30 日）。本报告只确认“2025 年 6 月上线、首批约 60 只”，**具体上线日未验证**。
  - https://eco.com/support/en/articles/15083158-kraken-xstocks-explained
  - https://coinpaprika.com/education/tokenized-stocks-explained

**赎回——事实：**

- 零售用户一般不能直接向发行方赎回正股。Kraken / Backed 的安排是：通过 KYC 的合资格投资者可直接与 Backed 交易、按 1:1 以现金价值赎回（有结算窗口与最低金额要求）；零售用户在 Kraken 上退出 xStocks 的方式是把代币卖回 USD / USDT。来源：
  - https://eco.com/support/en/articles/15083158-kraken-xstocks-explained
  - https://cleansky.io/blog/xstocks-vs-ondo-vs-robinhood-tokenized-stocks-2026/
- 直接一级市场发行 / 赎回的最低金额：第三方研究称需 KYC 且最低 5,000 美元（数据截至 2026 年 9 月 26 日复核，引用 xStocks FAQ）。该数字未在本次打开的 Kraken 官方 FAQ 原文中看到，**列为未验证**，下单前以 Backed 当时条款为准。
  - https://ketjuresearch.com/register/xstocks/
- **推断**：赎回权掌握在发行方与做市商手里，是代币价格在盘中能贴近正股的关键套利通道；零售用户没有这条通道，意味着盘外、流动性差时价格偏离要由自己承担，不能指望随时“按正股价格赎回”。

### 1.2 Ondo Stocks（Ondo Global Markets / Ondo Finance）

**事实：**

- 发行方是 Ondo Global Markets (BVI) Limited（英属维尔京群岛公司），产品现称 Ondo Stocks，2025 年 9 月上线（2025 年 9 月 3 日上线，首批 100 多只股票与 ETF）。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
  - https://www.techflowpost.com/en-US/article/28026
  - https://ondo.finance/blog/ondo-stocks-live-on-robinhood-chain-and-uniswap
- 法律性质是总回报追踪票据 / 结构性票据：持有人获得对标的公开证券的经济敞口（价格 + 分红再投资后的总回报），而不是直接拥有标的证券，也无权收取标的证券本身。Ondo 官方 FAQ 明确：代币可赎回为稳定币，而不是正股；代币不赋予直接所有权。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
- 托管：每一枚代币由对应的股票 / ETF 全额抵押，另加在途现金；标的存放在一家或多家美国注册的托管经纪商（licensed U.S. custodial broker-dealers）；发行方须保持超额抵押；独立第三方担保代理人 Ankura Trust Company 持有对抵押品的第一顺位、已完善的担保权益，在发行方违约等特定事件下可接管抵押品、变现并分配给持有人。Ondo 称由 Ankura 每日核验持仓，每日鉴证自 2025 年 10 月 1 日起可在线查看。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
  - https://www.assetera.com/media/assetera-x-ondo
- 具体是哪家美国经纪商：第三方报道称 Ondo 通过经纪商合作方买入并持有标的，并点名 Alpaca Markets 为美国注册经纪商、Ankura Trust 为独立核验方；但 Ondo 官方 FAQ 只写“一家或多家美国注册的托管经纪商”，未点名。**托管方名称以官方口径为准，Alpaca 这一名字列为二手来源，未验证**。
  - https://cryptocompass.com/articles/ondo-finance-tokenized-stocks-land-on-jumper-across-four-chains
- 链：Ethereum、BNB Chain、Solana；可桥接到 HyperEVM 与 Robinhood Chain。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
- 规模（注明日期，均为发行方 / 通讯稿口径）：
  - 2026 年 8 月 15–16 日：Ondo Stocks TVL 约 10.1 亿美元，累计交易量 270 亿美元，资产 440 多只；Ondo Perps 累计交易量 80 亿美元。来源：
    - https://tools.prnewswire.com:443/en-us/live/16934/release/20260814NY26855?filter=16934
  - 2026 年 10 月 27 日：Ondo 称 TVL 约 13 亿美元，累计持有人超 45 万，资产超 450 只。来源：
    - https://ondo.finance/blog/ondo-stocks-live-on-robinhood-chain-and-uniswap
  - 全市场规模：第三方汇总称截至 2026 年 11 月 8 日，代币化股票总值约 37.4 亿美元、持有人约 476 万（rwa.xyz 口径）；另一汇总称截至 2026 年 9 月 15 日约为 29.2 亿美元。两者日期与统计口径不同，**不直接比较**。
    - https://blockchainreporter.net/what-are-tokenized-stocks/
    - https://eco.com/support/en/articles/15083156-tokenized-stocks-explained

**赎回——事实：**

- 直接铸造 / 赎回只对完成 Ondo Stocks KYC 与准入流程的人开放，且仅向美国境外的非美国人士，以及欧洲经济区与英国的合资格投资者提供。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
- 第三方复核（2026 年 10 月 20 日）称：Ondo 的直接赎回目前仅对 KYC 后的机构参与者开放，零售用户主要靠二级市场卖出。该说法与官方“须完成 KYC”的口径一致，但“仅机构”的限定未在官方 FAQ 原文中看到，**列为未验证**。
  - https://www-rc3.weex.tech/learn/articles/are-tokenized-stocks-backed-by-real-shares-what-holders-own-eu3hf30p1ezvb6vswniik137
- **推断**：与 xStocks 相同，Ondo 的零售用户也没有可依赖的“随时按正股赎回”通道；一级市场是机构与发行方的通道，二级市场价格才是零售用户真正面对的价格。

### 1.3 一个容易误解的点：OUSG 不是股票代币

OUSG 是 Ondo 的短期美国国债基金代币（Ondo I LP 的有限合伙权益），主要投向短期美债与政府支持企业证券，需同时满足合格投资者与合格购买人要求；与 Ondo Stocks（股票 / ETF 代币）是不同产品，不要混为一谈。来源为二手汇总，引用 Ondo 产品说明；本报告不展开 OUSG，只作区分。

### 1.4 其他主流发行方（简述，供对照）

- **Binance bStocks**：由 BTech Holdings 发行，Binance 上现货交易，称代币与正股 1:1 兑换不收费，成本在 Binance 现货手续费里（0.10% maker/taker，用 BNB 付为 0.075%）。数据为第三方汇总（2026 年 10 月），**未在 Binance 官方页面复核**。
  - https://coinpaprika.com/education/xstocks-ondo-bstocks-robinhood
- **Robinhood**：分两代。Classic Stock Tokens 是 Robinhood Europe 提供的场外衍生品合约，只能在 App 内买卖，不能转出钱包；新一代 Stock Tokens（2026 年 7 月 1 日随 Robinhood Chain 主网上线）是由 Robinhood Assets (Jersey) Limited 发行的代币化债务证券，称 1:1 由托管股份抵押，可自托管。两者都不给投票权。来源：
  - https://robinhood.com/eu/en/support/articles/about-stock-tokens/
  - https://eco.com/support/en/articles/15083160-robinhood-tokenized-stocks-what-s-live-and-how-it-works
- **美国本土合规路线（与离岸产品不同）**：Securitize Stocks 于 2026 年 10 月 8 日上线，通过注册经纪商交易，称保留股东权利、可转为直接持股；Ondo 于 2026 年 7 月 2 日另推美国本土代币化证券模式（首批 IVV 与 Micron），通过 SEC 注册过户代理、经 Broadridge 代理投票。以上为二手来源，**本报告未复核其官方条款**，仅说明“美国本土产品与离岸 xStocks / Ondo Stocks 是两条不同路线”。
  - https://www-rc3.weex.tech/learn/articles/are-tokenized-stocks-backed-by-real-shares-what-holders-own-eu3hf30p1ezvb6vswniik137
  - https://blockchainreporter.net/what-are-tokenized-stocks/

---

## 2. 交易时间与交易场所：是否 24/7、节假日能否交易、在哪些平台能买到

### 2.1 xStocks

**事实：**

- Kraken App / 网站的官方口径（2026-11-09 抓取）：“在大多数非欧洲经济区地区，许多 xStocks 可以 24/7 买卖，包括周末；在欧洲经济区，xStocks 为 24/5，周一至周五。具体以 App 内各资产页面为准。”另一 Kraken 页面则写“24 小时、每周一至周五”。两者口径的差异来自地区与资产，**不是全市场统一的 24/7**。
  - https://www.kraken.com/gb/xstocks
- Kraken Pro 上 10 只票据可 24/7 交易（FAQ 更新于 2026 年 9 月 18 日）：TSLAx、QQQx、SPYx、NVDAx、CRCLx、AAPLx、HOODx、MSTRx、GLDx、GOOGLx；其余为 24/5。来源为第三方汇总引用 Kraken FAQ（2026 年 11 月 6 日更新的平台比较）。
  - https://blockchainreporter.net/where-to-buy-tokenized-stocks/
- 链上转移本身 24/7 可进行，但流动性与准确报价在盘外会变弱。Kraken 官方 FAQ 也写：股市收盘后，xStock 仍可在 Kraken 上交易，价格可能略微偏离上一个市价，直至市场重开。来源：
  - https://www.kraken.com/gb/xstocks
- **节假日**：本次核查中，Kraken 官方 FAQ 没有逐一列出美股节假日的 xStocks 交易安排。**美股节假日现货是否停牌、是否与周末同等处理，未查到官方明确说法，列为未查到**。可确认的是 Kraken 的 xStocks 永续合约称 24/7 交易，包括周末与公共假期（见第 5 节），但永续合约不等于现货代币。
- **场所（事实，注明日期）**：
  - Kraken（App 与 Kraken Pro）：官方主渠道；Kraken 支持页（2026 年 10 月 30 日更新）称 131 只资产（100 只股票、27 只 ETF、4 只专项资产），覆盖 110 多个国家；Kraken 页面（2026-11-09 抓取）则称 1,000+ xStocks——后者包括 2026 年 10 月 22 日宣布扩展的英国、欧洲与香港市场股票，不等于美股 xStocks 的数量，两者口径不同，**不要混用**。
    - https://support.kraken.com/articles/xstocks-faq
    - https://www.kraken.com/gb/xstocks
  - Bybit、OKX、Bitget、Jupiter（Solana DEX）等也上线 xStocks：第三方追踪（2026 年 10 月 18 日发布）列出 Bybit 上线 COIN、NVDA、AAPL 等 xStocks，OKX 上线 40 多只 xStocks，Bitget 等亦有；但各平台的可及地区与具体清单不同，**以各平台当时页面为准**。
    - https://nexualpha.com/data/tokenized-stock-tracker
  - Kraken 于 2025 年 12 月完成对 Backed Finance 的收购（第三方汇总称 2025 年 12 月；另有来源称 2024 年 12 月，日期冲突，**收购月份未验证**，不影响产品机制判断）。

**地区限制——事实：**

- xStocks 不向美国人士提供，也不在美国、加拿大、英国、澳大利亚提供。来源：
  - https://www.kraken.com/gb/xstocks
  - https://support.kraken.com/articles/xstocks-faq
- Kraken 的受限国家清单（2026 年 9 月 30 日更新，第三方复核）未列出中国内地与香港；但另有第三方（2026 年 10 月 15 日）指出，2026 年 2 月 6 日中国人民银行等八部门发布 42 号文，禁止一切加密业务并禁止境外平台向境内用户提供服务，境外平台向内地居民提供服务违反中国规则、可能随时关闭。**Chen 若在中国内地，这是第一位的合规风险，本报告无法替 Chen 判断其所在地是否合规，需自行核对 Kraken 当时条款与本地规则**。
  - https://www.coinperps.com/learn/best-crypto-exchanges-china

### 2.2 Ondo Stocks

**事实：**

- 直接铸造 / 赎回：24/5，周日美东 20:00 至周五美东 19:59；代币之间点对点交易可 24/7 进行。来源为 Ondo 官方 FAQ。
  - https://docs.ondo.finance/partner-docs/user-faq
- 2026 年 6 月起，Ondo 称对 6 只票据、仅机构用户试点 24/7 铸造与赎回。该说法来自第三方汇总（2026 年 9 月），**未在 Ondo 官方 FAQ 原文中看到，列为未验证**。
  - https://coinpaprika.com/education/xstocks-ondo-bstocks-robinhood
- **场所**：Ondo 官方直接平台（需 KYC）；第三方钱包、交易所与 DeFi 应用；2026 年 10 月 7 日 Assetera 在 30 个欧洲经济区国家上线 450 多只 Ondo 代币化股票与 ETF（初期 100 多只，2026 年第四季度扩展至全部）；2026 年 10 月 27 日 Ondo 上线 Robinhood Chain，15 只股票 / ETF 可在 Uniswap v4 StablePair 池交易；2026 年 11 月 7 日 Binance Alpha 与 Ondo 合作上线 10 只代币化美股 / ETF / 商品挂钩产品。以上均为发行方或平台公告口径，日期见来源。
  - https://www.assetera.com/media/assetera-x-ondo
  - https://ondo.finance/blog/ondo-stocks-live-on-robinhood-chain-and-uniswap
  - https://bitrss.com/binance-revives-tokenized-equities-in-ondo-finance-deal-187257
- **地区限制**：仅向美国境外的非美国人士，以及欧洲经济区与英国的合资格投资者提供；不对美国人士开放。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
- **节假日**：Ondo 官方 FAQ 只写了 24/5 的周日–周五窗口，未单独说明美股节假日是否暂停铸造 / 赎回。**节假日安排未查到，列为未查到**。

### 2.3 小结

- “24/7”只在部分资产、部分地区、部分渠道成立；最稳妥的理解是 **“24/5 为主，少数头部资产 24/7，链上转移 24/7 但不等于随时有好价格”**。
- 周末与节假日能交易，不等于能按正股价格交易——做市商无法在美股休市时对冲，价差与偏离都会放大（见第 4 节）。

---

## 3. 费用与点差：买卖点差、平台手续费、与正股相比贵多少

### 3.1 xStocks 在 Kraken 的费用（官方口径为主）

**事实：**

- Kraken App：用 USD 或 USDG（Kraken 的美元稳定币）购买 xStocks，无交易费；用其他资产购买，适用标准 Instant Buy 交易费；为锁定价格，报价中可能包含点差。来源（2026-11-09 抓取）：
  - https://www.kraken.com/gb/xstocks
- Kraken 风险披露页的口径更具体：所有 xStocks 的买入价为“市价 +1.0% 点差”；用 USDG / USD 以外的加密资产或法币购买，另收标准 Instant Buy / Sell 费；用 USDG / USD 购买则不另收费。来源：
  - https://www.kraken.com/legal/xstocks
- **两个官方口径不一致**：FAQ 说“可能包含点差”，风险披露页写明“+1.0% 点差”。本报告不调和这一矛盾，**结论是：App 内实际报价的点差必须在下单前实测，以当时 App 显示为准；1.0% 应视为可能成本的上限参考，而非承诺的固定值**。
- Kraken Pro：第三方汇总引用 Kraken 费率表称，自 2026 年 10 月 5 日起，入门档 maker 0.000%、taker 0.080%，30 日交易量超 10 亿美元后 maker -0.010%、taker 0.025%；另有平台比较（2026 年 11 月 6 日，引用 2026 年 9 月 18 日 FAQ）称 Pro taker 为 0.10%，xStocks 之间转换为固定 1%。两者日期与档位不同，**以 Kraken 当时费率表为准**。
  - https://eco.com/support/en/articles/15083158-kraken-xstocks-explained
  - https://blockchainreporter.net/where-to-buy-tokenized-stocks/
- 发行方层面（招股文件上限，二手汇总，2026 年 10 月）：管理费最高每年 0.25%，一级发行费最高 0.5%（最低 100 美元），赎回费最高 0.5%（最低 100 美元）。这是招股文件允许的上限，**不等于 Kraken App 零售用户实际支付的费用**；零售用户在 Kraken 上买卖一般不直接付这笔发行 / 赎回费，但大额直接赎回时可能触及。
  - https://coinpaprika.com/education/xstocks-ondo-bstocks-robinhood
- 最低投资：1 美元起，可买碎股。来源：
  - https://www.kraken.com/gb/xstocks
- 链上成本：提到钱包后，转账需付所在链的 Gas 费；Kraken 页面未给出具体 Gas 数字，**以当时链上实际费用为准，未查到统一数字**。

### 3.2 Ondo Stocks 的费用（官方口径为主）

**事实：**

- Ondo 官方 FAQ：发行方 Ondo Global Markets (BVI) Limited 目前对铸造或赎回不收费；用户需自行付 Gas 费；铸造与赎回价可能因波动与延迟调整而不完全等于标的价。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
- 但“不收费”不等于“零成本”：Ondo 的报价是按需生成的自有报价，价差未公开。第三方实时比较工具（2026-11-09 07:59 UTC 快照）称：Ondo 按请求生成报价，基于其库存与市场状况，价差未披露，价格只有在 App 内请求报价时才知道，无法提前核价；其链上池子极小（14 只代币池子持有量均 ≤ 2,600 美元，4 只为空池），链上显示的价格是旧成交的残留，不是可成交报价。来源：
  - https://stackfi.io/tools/tokenized-stock-premium/
- 个别产品的最终条款（Final Terms，Citigroup 标的，2026 年 5 月 27 日）写明：发行与赎回的投资者费用最高为标的市价的 0.1%，由发行方酌情决定。这是**单个产品的最终条款**，不是 Ondo 全产品的统一费率，**不要推广到所有 Ondo 代币**。
  - https://cdn.sanity.io/files/8k2tqa6n/production/18f4c5384138eacf72906f093f1061d51e187522.pdf
- 第三方文章称 Ondo 每笔交易费约 0.01–0.03%（约 1,000 美元交易付约 1 美元），该说法与官方“目前不收铸造 / 赎回费、价差未披露”的口径不一致，且未注明是哪一产品的条款。**该 0.01–0.03% 列为未验证**。
  - https://www.techflowpost.com/en-US/article/28026
- 最低金额：Ondo 官方 FAQ 未在本次打开的页面中给出统一最低金额；第三方汇总称最低 1 美元，另一份最终条款称最低认购额为 0.01 USDC。两者口径不同，**最低金额以当时 App / 产品条款为准，未验证统一值**。
  - https://coinpaprika.com/education/xstocks-ondo-bstocks-robinhood
  - https://cdn.sanity.io/files/8k2tqa6n/production/18f4c5384138eacf72906f093f1061d51e187522.pdf

### 3.3 与正股相比贵多少

**事实：**

- 美股正股在美国券商多为零佣金：Kraken 自身的美国股票业务称通过 Kraken Securities LLC（SEC 注册经纪商）提供免佣金美股与 ETF（第三方比较，2026 年 10 月）。来源：
  - https://www.datawallet.com/crypto/kraken-vs-okx
- **定性比较（推断，基于上述事实）**：
  - 盘中、流动性好的头部资产：代币的显性手续费可能与正股接近（Kraken App 用 USD 买称零交易费；Pro taker 约 0.08% 量级），但**点差是主要差距**——正股大盘股盘中买卖价差通常很小，而代币在 App 内报价可能含 1.0% 点差（按风险披露页口径），或在 Pro / DEX 上随流动性波动。
  - 盘外 / 周末 / 小票：代币的点差与溢价会明显扩大，正股此时根本无法交易，两者不可直接比较——代币多付的是“随时能交易”的溢价。
  - 频繁交易：代币的点差成本会快速累积；按风险披露页 1.0% 点差口径，一买一卖的往返点差成本可达约 2%（推断：1% 买入点差 + 1% 卖出点差，具体以实际报价为准），远高于正股零佣金 + 小价差的往返成本。**这不是实测数据，是按官方披露口径的算术推断**。
- **未查到**：没有找到 xStocks / Ondo 官方公布的、可与正股直接对比的统一历史平均点差表（例如分时段、分票据的日均买卖价差）。本报告不编造这一数字；Chen 若要精确比较，应在同一时点分别记录 Kraken / Ondo 报价与正股实时价，至少做 3–5 次不同时段的实测。

---

## 4. 跟踪误差与脱锚风险：偏离的历史案例、幅度、什么情况下会脱锚

### 4.1 历史偏离案例（有日期与幅度）

**事实：**

- 2025 年 7 月 3 日：AAPLX（Apple 代币）短暂冲至 236.72 美元，较标的 Apple 股票溢价约 12%。来源（CCN，2025 年 7 月 19 日发布）：
  - https://www.ccn.com/news/technology/tokenized-stocks-liquidity-challenges/
- 2025 年 7 月 5 日盘后：一个追踪 Amazon 的代币短暂涨至接近前收盘价的约 4 倍。来源同上。**该案例未注明具体是哪个发行方 / 平台的代币，幅度极端且为短暂闪崩式报价，不应理解为 Amazon 代币长期偏离 4 倍**。
  - https://www.ccn.com/news/technology/tokenized-stocks-liquidity-challenges/
- 2025 年 6 月 Robinhood 股票代币上线初期：价格与标的资产偏离约 1–2%；其他交易所的代币化股票也出现类似偏离。来源同上。
  - https://www.ccn.com/news/technology/tokenized-stocks-liquidity-challenges/
- 2026 年 11 月 9 日前后的周末价格发现案例（不是脱锚，是周末真实定价）：Hyperliquid 上 NVDA 永续合约在周日跌破 180 美元，而周五收盘为 186.64 美元；同期代币化 NVDAX 在 24 小时内下跌 3.55% 至 180.42 美元；Hyperliquid NVDA 永续 24 小时交易量约 1.89 亿美元。来源为第三方报道（2026 年 11 月 9 日发布），引用 Lookonchain 链上数据。该案例说明周末代币价格可以先行反映消息，而不是等周一开盘。
  - https://asiatokenfund.com/hyperliquid-whale-bets-5-4m-against-nvidia-over-jensen-huangs-spy-scandal/

**事实补充：**

- Chainlink 的代币化股票价格源文档称：代币化股票价格源提供 24/5 定价，少数资产提供 24/7 平滑价格源，周末与美股假期用永续期货市场推导的盘外价格；夜间流动性最薄时，发布价是指数移动平均而非最新观测值，并对盘中切换与隔夜时段做平滑，以减少短暂 spikes 造成的异常。来源：
  - https://docs.chain.link/data-feeds/tokenized-equity-feeds
- Jupiter 的 xStocks 指南（更新于 2026 年 10 月 12 日）称：链上价格仍可能相对股票溢价或折价交易；大多数代币化股票可 24/7 交易，部分 Ondo 代币为 24/5 并可能有额外交易暂停；流动性通常在美股开盘时最深。来源：
  - https://docs.jup.ag/user-docs/guides/stocks/how-tokenized-stocks-work

### 4.2 什么情况下会脱锚

**事实 + 推断（分开写）：**

- **美股休市时（事实）**：Kraken 官方承认，股市收盘后 xStock 价格可能略微偏离上一个市价，直至市场重开；做市商无法通过标的市场对冲，只能凭订单簿报价。来源：
  - https://www.kraken.com/gb/xstocks
- **流动性薄的票据与小池子（事实）**：StackFi 2026-11-09 快照显示，Ondo 多只代币的链上池子持有量 ≤ 2,600 美元，4 只为空池，单笔订单即可大幅移动价格；xStocks 在 Solana DEX 上头部票据池子较深（10.4 万至 293 万美元量级），但小票仍薄。来源：
  - https://stackfi.io/tools/tokenized-stock-premium/
- **赎回通道不对零售开放（事实，见第 1 节）**：CCN（2025 年 7 月 19 日）指出，与稳定币发行方不同，Robinhood 与 xStocks 等不向持有人提供直接赎回标的资产的通道；套利依赖有资质的投资者 / 做市商在一级市场与订单簿之间搬砖。**推断**：当一级市场套利变慢（休市、结算延迟、发行方暂停铸造 / 赎回）或做市商撤单时，偏离会持续更久。
  - https://www.ccn.com/news/technology/tokenized-stocks-liquidity-challenges/
- **重大消息在周末落地（事实）**：2026 年 11 月 9 日 NVDA 案例即为周末消息先在代币 / 永续市场定价，周一美股开盘才确认。这不是“脱锚”，而是“提前定价”；但若周一开盘价与周末代币价差距大，周末买入者会立即承受跳空。
- **合约与假币风险（事实）**：StackFi 提醒，2026 年 9 月 12 日有多个仿冒代币的链上流动性一度超过真代币，买入前必须在发行方处核对合约地址。来源：
  - https://stackfi.io/tools/tokenized-stock-premium/
- **分红再投资造成的“价格偏离”（事实，不是脱锚）**：Ondo 代币是总回报追踪器，分红扣税后再投资，1 枚代币会逐渐代表超过 1 股，代币价会系统性高于正股价；xStocks 则通过余额增加（rebase）反映分红。两者都不是价格错误，但若直接拿代币价与正股价对比，会误以为“溢价”。来源：
  - https://docs.ondo.finance/partner-docs/user-faq
  - https://www.kraken.com/gb/xstocks

### 4.3 没有找到的跟踪误差数据

- **未查到**：xStocks 或 Ondo 官方公布的长期跟踪误差统计（例如 2025 年 6 月–2026 年 11 月的日均偏离、最大偏离、年化跟踪误差）。第三方只有零散案例与实时溢价工具，没有系统性回测。本报告不编造这一数字。
- **推断**：从机制上看，盘中头部资产的偏离应较小（做市商可实时对冲），盘外与小票的偏离应较大；但“应较小 / 较大”是推断，不是实测结论。Chen 若要量化，应在美股交易时段与盘外分别记录至少一周的溢价，再作判断。

---

## 5. 做空是否可行：能不能做空代币化美股，有什么限制

### 5.1 结论先行

**现货代币本身不能直接“卖空持有”；做空要通过保证金或永续合约实现，且只在部分平台、部分资产、部分地区可行，杠杆越高风险越大。**

### 5.2 Kraken：保证金做空（事实）

- Kraken Pro 于 2026 年 2 月 20 日上线 xStocks 保证金交易：可做多或做空，最高 3 倍杠杆，按交易对交易（例如 TSLAx/USD），借入资金来自 Kraken PDSL 保证金池，保证金费用每 4 小时按借入金额计收，可用合资格账户余额作自动抵押。来源：
  - https://blog.kraken.com/product/xstocks/introducing-xstocks-margin-trading-on-kraken-pro
- 首批保证金交易对（2026 年 2 月 20 日）：NVDAx、TSLAx、AAPLx、SPYx、GOOGLx、GLDx、CRCLx、QQQx、MSTRx、HOODx。来源同上。
- 限制：仅向合资格客户提供，不在美国提供，其他地区限制适用；保证金交易有初始与维持保证金要求、实时清算逻辑、按订单簿深度设定的持仓上限与保证金池敞口上限。来源同上。
- 2026 年 7 月 3 日起，10 只 xStocks 可作期货与保证金交易的抵押品（SPYx、QQQx、AAPLx、GOOGLx、TSLAx、NVDAx 等），折扣率 10%–30%，各资产有抵押上限；期货抵押向美国境外合资格客户提供（含欧洲经济区），保证金抵押向美国境外合资格客户提供（不含欧洲经济区）。来源为 Kraken 博客二手汇总，**未在本次打开的官方原文中逐项复核折扣率**，以 Kraken 当时抵押品页面为准。
  - https://blog.kraken.com/product/xstocks/eligible-as-collateral-for-futures-and-margin

### 5.3 Kraken：永续合约做空（事实）

- Kraken 于 2026 年 2 月 24 日上线代币化股票永续合约：向 110 多个国家的合资格非美国客户提供 24/7 杠杆交易，最高 20 倍，标的包括 S&P 500、Nasdaq 100、黄金与 NVDA、AAPL、TSLA、GOOGL 等个股；合约以 xStocks 框架为基础，称使用受监管基准。来源：
  - https://blog.kraken.com/product/xstocks/tokenized-equity-perpetual-futures
- **注意**：永续合约是衍生品，不持有正股，也不持有现货代币；做空永续等于做空价格，不等于借入并卖出现货代币。资金费率、清算与 20 倍杠杆下的爆仓风险与现货完全不同。

### 5.4 Ondo：现货代币本身没有官方做空功能

- **未查到**：Ondo 官方 FAQ 与本次核查的 Ondo 产品页中，没有提供 Ondo Stocks 现货代币的融券 / 做空功能。Ondo 的做空要通过 Ondo Perps（永续合约）实现。
- Ondo Perps：2026 年 2 月 3 日宣布计划，2026 年 7 月上线；截至 2026 年 8 月累计交易量超 80 亿美元，过去 30 天超 50 亿美元，未平仓最高 8,700 万美元。来源为 Ondo 通讯稿二手汇总（2026 年 8 月）。
  - https://tools.prnewswire.com:443/en-us/live/16934/release/20260814NY26855?filter=16934
- **推断**：Ondo Perps 与 Kraken 永续一样，是价格衍生品，不是现货代币的做空；其资金费率、清算规则与可及地区需以 Ondo Perps 当时页面为准，本报告未逐项复核。

### 5.5 其他平台的股票永续（事实，供对照）

- Binance 于 2026 年 1 月 28 日上线 TSLAUSDT 股票永续合约，2 月 9 日再上线 MSTR、AMZN、CRCL、COIN、PLTR 等；Hyperliquid 于 2025 年 10 月通过 HIP-3 机制向第三方开放永续市场创建，迅速扩展到股票、指数、商品与外汇；Backpack、OKX、Bitget 等亦提供股票永续。以上为第三方汇总（2026 年 11 月），**各平台的可及地区与杠杆上限不同，且均不对美国人士开放**。
  - https://www.aicoin.com/en/article/555963
  - https://nexualpha.com/data/tokenized-stock-tracker
- 2026 年 11 月 3 日，美国商品期货交易委员会（CFTC）主席宣布单只股票永续合约首次获准在美国受监管交易所交易，纳入 CFTC 与 SEC 双重监管框架。该消息来自第三方中文报道（2026 年 11 月），**未在 CFTC / SEC 官方公告原文中复核**，且不等于 Chen 当下就能在美国本土交易所做空代币化美股。
  - https://www.aicoin.com/en/article/555963

### 5.6 做空的限制汇总

- **地区**：保证金与永续均不对美国人士开放，另有英国、加拿大、澳大利亚等限制；欧洲经济区客户的保证金抵押与永续可及性不同（见 5.2）。
- **资产**：只有头部 10 只左右有保证金 / 永续，小票没有可借券源，也没有永续。
- **成本**：保证金费用每 4 小时计收，永续有资金费率；具体费率随需求波动，**本次未查到统一的实时借券 / 资金费率表**。
- **风险**：杠杆做空的亏损可能超过本金（保证金清算），周末跳空无法及时平仓，盘外流动性差时滑点大。**不建议小资金试水阶段做空**。

---

## 6. 与正股的关键差异汇总表

| 维度 | 正股（美股券商） | xStocks（Kraken / Backed） | Ondo Stocks（Ondo Global Markets） |
|---|---|---|---|
| **法律性质** | 上市公司股份，登记在持有人 / 托管人名下 | 追踪凭证（tracker certificate），泽西 SPV 发行；持有人无投票权、无对上市公司的直接权利 | 总回报追踪票据 / 结构性票据，BVI SPV 发行；持有人只有对发行方的经济敞口，无权收取正股 |
| **发行方** | 上市公司本身 | Backed Assets (JE) Limited | Ondo Global Markets (BVI) Limited |
| **托管方** | 券商 / DTCC 体系（T+1 结算） | 受监管托管方；二手来源称 Alpaca Securities / Alpaca Crypto（美国），InCore / Maerki Baumann（欧洲部分） | 一家或多家美国注册托管经纪商（官方未点名）；Ankura Trust 为担保代理人，每日核验 |
| **交易时间** | 美东 9:30–16:00（约 6.5 小时），盘前盘后有限延长；周末与美股假期休市 | Kraken：非 EEA 地区多只可 24/7，EEA 为 24/5；Kraken Pro 10 只可 24/7；链上转移 24/7 | 直接铸造 / 赎回 24/5（周日 20:00 ET–周五 19:59 ET）；点对点交易 24/7 |
| **交易场所** | NYSE / Nasdaq 等交易所，经券商下单 | Kraken（主渠道）、Bybit、OKX、Bitget、Jupiter 等；链上 DEX | Ondo 直接平台、Assetera、Binance Alpha、Robinhood Chain / Uniswap 池、Jumper 等 |
| **费用** | 美国券商多为零佣金；成本主要是买卖价差与监管费 | Kraken App 用 USD/USD G 称零交易费，但报价含点差（风险披露页：市价 +1.0%）；用其他资产付 Instant Buy 费；Pro taker 约 0.08%（2026-10-05 起入门档） | 官方称目前铸造 / 赎回不收费，Gas 自付；但报价价差未披露，须在 App 内请求报价后比较；个别产品最终条款最高 0.1% |
| **点差 / 溢价** | 盘中大盘股点差通常很小 | 盘中头部资产较贴近正股；盘外、周末、小票点差与溢价放大；2025 年 7 月曾出现 AAPLx +12%、Amazon 代币约 4 倍的短暂偏离 | 链上池子极小，链上显示价不是可成交报价；真实成本只在请求报价时可见；分红再投资会使代币价系统性高于正股价 |
| **分红处理** | 现金分红到账（扣税后），可自选再投资 | 自动再投资，xStocks 余额增加（rebase）；扣税后净额再投资（第三方称按 30% 美国预扣税） | 自动再投资，扣 30% 美国预扣税后的净额再投资；1 枚代币逐渐代表超过 1 股，代币价随之高于正股价 |
| **投票权** | 有（按持股） | 无 | 无（离岸 Ondo Stocks）；美国本土另推模式（2026 年 7 月 2 日，IVV 与 Micron）称经 Broadridge 代理投票，但那不是离岸 Ondo Stocks |
| **赎回** | 卖出即变现；持股本身可转移至其他券商 | 零售靠二级市场卖出；合资格投资者可向 Backed 直接赎回现金（KYC、最低金额，第三方称 5,000 美元，未验证） | 零售靠二级市场卖出；直接铸造 / 赎回只对 KYC 后的合资格人士开放，赎回为稳定币，不是正股 |
| **结算** | T+1（DTCC） | 链上 T+0（区块时间结算） | 链上结算；直接铸造 / 赎回按 24/5 窗口处理 |
| **最低投资** | 1 股（部分券商支持碎股） | 1 美元起，可买碎股 | 官方未统一注明；第三方称 1 美元起，个别产品条款称 0.01 USDC 起 |
| **监管归属** | SEC / FINRA 监管，交易所上市 | 泽西 SPV + 列支敦士登 FMA 批准的招股文件（欧盟招股条例下）；Kraken 通过百慕大 PDSL 提供；未在任何本地证券监管机构注册 | BVI SPV，Regulation S 下向非美国人士发售；未在美国注册；欧洲经济区与英国仅向合资格投资者提供 |
| **投资者保障** | 美国券商有 SIPC 等保障（以券商条款为准） | **未在官方 FAQ 查到 SIPC 保障**；第三方研究称无 SIPC，列为未验证 | **未在官方 FAQ 查到 SIPC 保障**；担保来自超额抵押 + Ankura 第一顺位担保权益，不是 SIPC |
| **可及地区** | 全球券商各有地区限制 | 不向美国人士提供；不在美国、加拿大、英国、澳大利亚提供；110 多个国家（2026-10-30） | 不向美国人士提供；仅美国境外非美国人士，以及 EEA 与英国合资格投资者 |
| **做空** | 券商融券（需借券、有利息与平仓规则） | Kraken Pro 保证金可做空（最高 3 倍，10 只）；Kraken 永续可做空（最高 20 倍） | 现货代币无官方做空功能；Ondo Perps 可做空价格（衍生品，2026 年 7 月上线） |
| **转移 / DeFi** | 不能提到钱包，不能进 DeFi | 可提到自托管钱包，可在 DEX 交易、作抵押、进 DeFi | 可转移（美国境外），可在 DEX / 钱包 / DeFi 应用中使用 |

**表注**：本表数据截至 2026-11-10 核查时点；费率、资产数量与可及地区以发行方与平台当时页面为准。美国本土合规代币化股票（Securitize Stocks 等）与离岸产品在投票权与赎回权上不同，不在本表内混用。

---

## 7. 给 Chen 的结论：现阶段适不适合小资金试水，如果试，第一步建议是什么

### 7.1 结论

**适合小资金试水，但只适合当作“学习 + 体验 24/5 交易”的小额实验，不适合当作正股的替代品或长期核心仓位。**

理由（事实支撑）：

- 产品已上线一年多，不再是只有白皮书的概念：xStocks 2025 年 6 月上线，Ondo Stocks 2025 年 9 月上线；截至 2026 年 10 月 27 日，Ondo TVL 约 13 亿美元、持有人超 45 万；xStocks 亦有 1 亿美元量级的抵押规模（2026 年 10 月第三方称 8.58 亿美元抵押，另有报道称破 10 亿美元，口径不同，见第 1 节）。市场已有一定的流动性与做市商套利机制。
- 但产品仍很年轻，历史只有约 17 个月，经历过的极端偏离案例集中在上线初期（2025 年 7 月），长期跟踪误差没有官方统计；发行方与托管链风险、监管变化风险都没有经过完整市场周期的检验。
- 成本上，代币在盘中可能与正股接近，但在盘外与频繁交易时明显更贵；分红不是现金到账，而是再投资后余额 / 价格变化，税务处理也与直接持股不同（30% 预扣税由发行方代扣后再投资）。

**推断**：如果 Chen 的目标是“持有 SPY / QQQ / AAPL / MSFT / NVDA / TSLA 的长期回报”，直接买正股（或正股 ETF）是更便宜、更确定、权利更完整的选择；如果目标是“体验 24 小时交易、碎片化、用 USDT 直接买美股敞口、提到钱包作抵押”，代币化美股才有不可替代的价值。两者目标不同，结论也不同。

### 7.2 试水前的自查清单（按顺序做，任一步不通过就停）

1. **身份与所在地**：确认自己不是美国人士，且所在地不在 Kraken / Ondo 的排除名单（美国、英国、加拿大、澳大利亚等）；若在中国内地，另需核对本地关于境外加密平台的规则（2026 年 2 月 6 日八部门 42 号文），不要绕过平台的地区限制。
2. **平台**：优先选 Kraken（xStocks 的官方主渠道），不要先去小平台或 DEX 买小票；确认 App 内能看到 xStocks，且能用 USD / USDG 购买。
3. **资产**：只买 SPYx / QQQx / AAPLx / NVDAx / TSLAx 这类头部、高流动性资产；不要买 SpaceX 等 IPO 代币、私募 / 未上市代币或小票。
4. **时间**：只在美股开盘时段买入与卖出；周末与深夜只观察、不交易。
5. **金额**：第一笔控制在 100 美元量级（可自行调低），总试水金额控制在“亏完也不影响生活”的范围内；不要用保证金、不要用永续、不要加杠杆。
6. **记录**：每次买卖都记录 Kraken 报价、同期正股实时价、算出的溢价 / 点差、Gas 费（如有）、卖出价差；一周后复盘，再决定是否继续。

### 7.3 第一步建议（具体、可执行）

> **第一步（本周内可做完）：在 Kraken 完成实名认证，在 App 内确认 xStocks 可见；在美股开盘时段，用 USD 买一笔小额 SPYx（例如 100 美元），截图保存买入价与同期 SPY 实时价，算出实际溢价；持有一周，观察分红再投资与周末偏离，卖出时再记录卖出价差。**

- 为什么选 SPYx：宽基 ETF、流动性最好、波动小于个股，最适合用来验证“成本与偏离”，而不是用来赌方向。
- 为什么选美股时段：盘中做市商能实时对冲，溢价最小；盘外买入等于主动承担偏离风险。
- 为什么先不做空、不加杠杆：保证金与永续的清算、资金费率与周末跳空风险，远大于现货小额试水的学习价值；先学会算现货成本，再考虑是否需要做空工具。
- 停止条件：若实测买入溢价持续高于 1%、或卖出时点差过大、或 App 内报价与正股价长期偏离超过 2%、或发现所在地合规有疑问，立即停止加仓，已持有的仓位在美股时段卖出，不要补仓摊薄。

### 7.4 风险清单（Chen 必须接受才能试）

- **发行方 / 托管风险**：Backed / Ondo 若破产、托管方出问题、抵押品被冻结，代币可能无法按正股价值赎回；虽有隔离账户、超额抵押与担保代理人，但这些是法律安排，不是存款保险。
- **脱锚 / 流动性风险**：盘外、周末、重大消息时，代币价可能大幅偏离正股价，且无法立即按正股价格卖出。
- **监管风险**：SEC 于 2026 年 1 月 28 日发布工作人员声明，称代币化证券仍是证券，第三方合成模式会增加交易对手、运营与破产风险；2026 年 9 月 17 日的创新豁免为期 5 年、范围有限，只覆盖与标的享有同等权利的代币。离岸 xStocks / Ondo Stocks 不在该豁免的直接覆盖范围内，未来规则变化可能影响可及性与赎回。
  - https://blockchainreporter.net/what-are-tokenized-stocks/
- **税务风险**：分红经 30% 预扣税后再投资，税务处理与直接持股不同；Chen 所在地的税务申报义务**未在本报告中核查，需自行咨询税务专业人士**。
- **操作风险**：提到钱包后，转错链、丢助记词、买到仿冒合约地址都无法撤回；2026 年 9 月 12 日曾出现仿冒代币流动性超过真代币的情况，买入前必须核对发行方公布的合约地址。
  - https://stackfi.io/tools/tokenized-stock-premium/
- **杠杆风险**：3 倍保证金与 20 倍永续的亏损可能超过本金，且周末无法及时平仓；小资金试水阶段不应使用。

### 7.5 如果 Chen 不想试，替代方案是什么

- 直接通过合规美股券商买正股 / ETF（SPY、QQQ、AAPL、MSFT、NVDA、TSLA），成本最低、权利最完整、税务最确定。
- 若人在美国或想保留投票权与直接持股，可关注美国本土合规代币化股票（Securitize Stocks 等），但需以其当时条款与可及地区为准，本报告未深入核查。
- 若只是想交易美股价格波动且能接受衍生品风险，可考虑合规的股票永续 / 期货，但那是另一类产品，不在本报告的现货代币结论内。

---

## 附录 A：研究方法与局限

- 研究日期 2026-11-10，以公开网络来源为主，优先采用发行方与平台官方页面（Kraken、Ondo），其次为可复核的第三方汇总与实时比较工具。
- 未开设 Kraken / Ondo 账户实测下单，未验证 App 内的实时报价、点差与地区准入；费率与可及地区以当时 App 内显示为准。
- 未查到 xStocks / Ondo 官方公布的长期跟踪误差统计，也未查到统一的实时借券 / 资金费率表；相关数字在正文中明确写“未查到”。
- 市场规模、资产数量等数字在不同日期、不同统计口径下差异较大，正文均注明日期与来源，不作跨期直接比较。
- 本报告不构成投资、法律或税务建议。

## 附录 B：来源清单（按首次出现顺序，链接 verbatim）

1. Kraken xStocks 页面（2026-11-09 抓取）— https://www.kraken.com/gb/xstocks
2. Kraken xStocks 风险披露 — https://www.kraken.com/legal/xstocks
3. Kraken xStocks 支持 FAQ（更新于 2026-10-30）— https://support.kraken.com/articles/xstocks-faq
4. Ondo Stocks 用户 FAQ — https://docs.ondo.finance/partner-docs/user-faq
5. Ondo Stocks 上线 Robinhood Chain（2026-10-27）— https://ondo.finance/blog/ondo-stocks-live-on-robinhood-chain-and-uniswap
6. Ondo Stocks 突破 10 亿美元（2026-08-14/16 通讯稿）— https://tools.prnewswire.com:443/en-us/live/16934/release/20260814NY26855?filter=16934
7. Assetera 上线 Ondo 代币（2026-10-07）— https://www.assetera.com/media/assetera-x-ondo
8. Kraken xStocks 保证金交易（2026-02-20）— https://blog.kraken.com/product/xstocks/introducing-xstocks-margin-trading-on-kraken-pro
9. Kraken 代币化股票永续合约（2026-02-24）— https://blog.kraken.com/product/xstocks/tokenized-equity-perpetual-futures
10. Kraken xStocks 抵押品（2026-07-03）— https://blog.kraken.com/product/xstocks/eligible-as-collateral-for-futures-and-margin
11. CCN 代币化股票流动性与偏离案例（2025-07-19）— https://www.ccn.com/news/technology/tokenized-stocks-liquidity-challenges/
12. CoinPaprika 代币化股票解释（数据截至 2026 年 10 月）— https://coinpaprika.com/education/tokenized-stocks-explained
13. CoinPaprika xStocks / Ondo / bStocks / Robinhood 比较（数据截至 2026 年 10 月）— https://coinpaprika.com/education/xstocks-ondo-bstocks-robinhood
14. Eco Kraken xStocks 解释 — https://eco.com/support/en/articles/15083158-kraken-xstocks-explained
15. Eco 代币化股票解释 — https://eco.com/support/en/articles/15083156-tokenized-stocks-explained
16. Cleansky xStocks / Ondo / Robinhood 比较（数据截至 2026-07-26）— https://cleansky.io/blog/xstocks-vs-ondo-vs-robinhood-tokenized-stocks-2026/
17. StackFi xStocks / Ondo 实时溢价比较（快照 2026-11-09 07:59 UTC）— https://stackfi.io/tools/tokenized-stock-premium/
18. Jupiter xStocks 指南（更新于 2026-10-12）— https://docs.jup.ag/user-docs/guides/stocks/how-tokenized-stocks-work
19. Chainlink 代币化股票价格源文档 — https://docs.chain.link/data-feeds/tokenized-equity-feeds
20. BlockchainReporter 代币化股票平台比较（更新于 2026-11-06）— https://blockchainreporter.net/where-to-buy-tokenized-stocks/
21. BlockchainReporter 代币化股票总览（更新于 2026-11-08）— https://blockchainreporter.net/what-are-tokenized-stocks/
22. Robinhood Classic Stock Tokens 说明 — https://robinhood.com/eu/en/support/articles/about-stock-tokens/
23. Eco Robinhood 代币化股票说明（截至 2026-10-08）— https://eco.com/support/en/articles/15083160-robinhood-tokenized-stocks-what-s-live-and-how-it-works
24. NexuAlpha 代币化股票追踪（发布于 2026-10-18）— https://nexualpha.com/data/tokenized-stock-tracker
25. Ondo 最终条款示例（Citigroup，2026-05-27）— https://cdn.sanity.io/files/8k2tqa6n/production/18f4c5384138eacf72906f093f1061d51e187522.pdf
26. TechFlow Ondo Global Markets 解析 — https://www.techflowpost.com/en-US/article/28026
27. Weex 代币化股票抵押结构复核（截至 2026-10-20）— https://www-rc3.weex.tech/learn/articles/are-tokenized-stocks-backed-by-real-shares-what-holders-own-eu3hf30p1ezvb6vswniik137
28. Kraken / OKX 比较（2026 年 10 月）— https://www.datawallet.com/crypto/kraken-vs-okx
29. CoinPerps 中国交易所指南（2026-10-15）— https://www.coinperps.com/learn/best-crypto-exchanges-china
30. Aicoin 美国单只股票永续报道（2026 年 11 月）— https://www.aicoin.com/en/article/555963
31. AsiaTokenFund Hyperliquid NVDA 做空报道（2026-11-09）— https://asiatokenfund.com/hyperliquid-whale-bets-5-4m-against-nvidia-over-jensen-huangs-spy-scandal/
32. Binance 与 Ondo 合作（2026-11-07）— https://bitrss.com/binance-revives-tokenized-equities-in-ondo-finance-deal-187257
33. Ketju xStocks 研究备忘（复核于 2026-09-26）— https://ketjuresearch.com/register/xstocks/
34. CryptoCompass Ondo 上线 Jumper 报道 — https://cryptocompass.com/articles/ondo-finance-tokenized-stocks-land-on-jumper-across-four-chains

---

*— node-1，2026-11-10*
