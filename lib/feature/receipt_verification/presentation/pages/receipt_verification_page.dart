import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gear_track/feature/receipt_verification/presentation/bloc/receipt_verification_bloc.dart';
import 'package:gear_track/feature/receipt_verification/presentation/widgets/verification_error_card.dart';
import 'package:gear_track/feature/receipt_verification/presentation/widgets/verification_loading_view.dart';
import 'package:gear_track/feature/receipt_verification/presentation/widgets/verification_manual_input.dart';
import 'package:gear_track/feature/receipt_verification/presentation/widgets/verification_mode_tab.dart';
import 'package:gear_track/feature/receipt_verification/presentation/widgets/verification_scanner_view.dart';
import 'package:gear_track/feature/receipt_verification/presentation/widgets/verified_invoice_card.dart';

class ReceiptVerificationPage extends StatefulWidget {
  final bool allowReturn;

  const ReceiptVerificationPage({super.key, this.allowReturn = false});

  @override
  State<ReceiptVerificationPage> createState() =>
      _ReceiptVerificationPageState();
}

class _ReceiptVerificationPageState extends State<ReceiptVerificationPage> {
  final TextEditingController _idController = TextEditingController();
  int _selectedTabIndex = 0; // 0: Live Scanner, 1: Manual ID

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  void _verify(String rawCode) {
    final cleanCode = rawCode.trim();
    if (cleanCode.isEmpty) return;
    context.read<ReceiptVerificationBloc>().add(
      VerifyReceiptCodeEvent(cleanCode),
    );
  }

  void _reset() {
    _idController.clear();
    context.read<ReceiptVerificationBloc>().add(
      ResetReceiptVerificationEvent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Verify Receipt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        body: SafeArea(
          child: BlocBuilder<ReceiptVerificationBloc, ReceiptVerificationState>(
            builder: (context, state) {
              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state is ReceiptVerificationLoading)
                      const VerificationLoadingView()
                    else if (state is ReceiptVerificationSuccess)
                      VerifiedInvoiceCard(
                        invoice: state.invoice,
                        onReset: _reset,
                        showReturnButton: widget.allowReturn,
                      )
                    else if (state is ReceiptVerificationFailure)
                      VerificationErrorCard(
                        errorMessage: state.errorMessage,
                        scannedCode: state.scannedCode,
                        onRetry: _reset,
                      )
                    else ...[
                      VerificationModeTab(
                        selectedIndex: _selectedTabIndex,
                        onTabChanged: (index) =>
                            setState(() => _selectedTabIndex = index),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedTabIndex == 0)
                        VerificationScannerView(onScanned: _verify)
                      else
                        VerificationManualInput(
                          controller: _idController,
                          onVerify: _verify,
                        ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
